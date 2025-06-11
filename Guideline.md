# Migration Guide: Aurora to Containerized MySQL on EC2

This document provides step-by-step instructions for migrating from Amazon Aurora to a containerized MySQL database running on a dedicated EC2 instance in the eu-west-1a Availability Zone.

## Overview

The migration will involve:
1. Setting up a new EC2 instance in eu-west-1a
2. Deploying MySQL in a Docker container
3. Migrating data from Aurora to the containerized MySQL
4. Updating application configurations
5. Testing and cutover

## Prerequisites

- AWS CLI configured with appropriate permissions
- Docker knowledge and experience
- Database administration skills
- Access to the current Aurora database
- Backup of all current data

## Detailed Migration Steps

### 1. Prepare the CloudFormation Changeset

Create a CloudFormation changeset that will:
- Add a new EC2 instance for the MySQL database
- Configure appropriate security groups
- Remove the Aurora database resources

```yaml
# Add to your CloudFormation template:

  # MySQL Database EC2 Instance
  MySQLDBInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-03400c3b73b5086e9  # Amazon Linux 2023 AMI for eu-west-1
      InstanceType: t2.micro  # Adjust based on your database requirements
      SubnetId: !Ref DBSubnet1  # Placing in eu-west-1a
      SecurityGroupIds:
        - !Ref DBSecurityGroup
      KeyName: !Ref KeyName
      IamInstanceProfile: !Ref DBInstanceProfile
      BlockDeviceMappings:
        - DeviceName: /dev/xvda
          Ebs:
            VolumeSize: 20  # Adjust based on your storage needs
            VolumeType: gp3
            DeleteOnTermination: false
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-MySQL-DB-Server
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash -xe
          # Update system
          yum update -y
          
          # Install Docker
          amazon-linux-extras install docker -y
          systemctl start docker
          systemctl enable docker
          
          # Create directories for MySQL data and configuration
          mkdir -p /data/mysql
          mkdir -p /data/mysql/conf.d
          
          # Create MySQL configuration file
          cat > /data/mysql/my.cnf << 'EOF'
          [mysqld]
          character-set-server = utf8mb4
          collation-server = utf8mb4_unicode_ci
          default-authentication-plugin = mysql_native_password
          max_connections = 20
          innodb_buffer_pool_size = 1G
          EOF
          
          # Run MySQL container
          docker run --name mysql-server \
            -v /data/mysql:/var/lib/mysql \
            -v /data/mysql/my.cnf:/etc/mysql/my.cnf \
            -v /data/mysql/conf.d:/etc/mysql/conf.d \
            -e MYSQL_ROOT_PASSWORD=${DBPassword} \
            -e MYSQL_DATABASE=${DBName} \
            -e MYSQL_USER=${DBUsername} \
            -e MYSQL_PASSWORD=${DBPassword} \
            -p 3306:3306 \
            --restart always \
            -d mysql:8.0
            
          # Install CloudWatch agent
          yum install -y amazon-cloudwatch-agent
          
          # Configure CloudWatch agent
          cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
          {
            "agent": {
              "metrics_collection_interval": 60,
              "run_as_user": "root"
            },
            "metrics": {
              "metrics_collected": {
                "disk": {
                  "measurement": ["used_percent"],
                  "metrics_collection_interval": 60,
                  "resources": ["/"]
                },
                "mem": {
                  "measurement": ["mem_used_percent"],
                  "metrics_collection_interval": 60
                },
                "swap": {
                  "measurement": ["swap_used_percent"],
                  "metrics_collection_interval": 60
                }
              }
            },
            "logs": {
              "logs_collected": {
                "files": {
                  "collect_list": [
                    {
                      "file_path": "/var/log/docker",
                      "log_group_name": "/aws/ec2/mysql/docker",
                      "log_stream_name": "{instance_id}",
                      "retention_in_days": 7
                    }
                  ]
                }
              }
            }
          }
          EOF
          
          # Start CloudWatch agent
          /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

  # IAM Role for DB EC2 instance
  DBRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
        - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
      Path: /

  DBInstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Path: /
      Roles:
        - !Ref DBRole

  # Remove these resources:
  # - AuroraDBCluster
  # - AuroraPrimaryInstance
  # - AuroraReplicaInstance
```

### 2. Data Migration Process

#### 2.1 Create a Backup of Aurora Database

```bash
# Create a snapshot of your Aurora database
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier <your-aurora-cluster-id> \
  --db-cluster-snapshot-identifier migration-snapshot

# Wait for the snapshot to complete
aws rds wait db-cluster-snapshot-available \
  --db-cluster-snapshot-identifier migration-snapshot
```

#### 2.2 Export Data from Aurora

```bash
# Connect to Aurora and export data
mysqldump -h <aurora-endpoint> -u <username> -p<password> \
  --single-transaction --routines --triggers --events \
  todo_app > todo_app_backup.sql
```

#### 2.3 Import Data to the New MySQL Container

```bash
# Copy the SQL dump to the EC2 instance
scp -i <your-key.pem> todo_app_backup.sql ec2-user@<mysql-ec2-ip>:/tmp/

# SSH into the EC2 instance
ssh -i <your-key.pem> ec2-user@<mysql-ec2-ip>

# Import the data into the containerized MySQL
docker exec -i mysql-server mysql -u<username> -p<password> todo_app < /tmp/todo_app_backup.sql
```

### 3. Update Application Configuration

Update the database connection settings in your application:

```php
// Update api/config.php
$db_host = '<mysql-ec2-private-ip>'; // New MySQL server IP
$db_name = 'todo_app';
$db_user = 'admin'; // Using the username from CloudFormation parameters
$db_pass = ''; // Password should be set during deployment, not stored in code
```

### 4. Testing and Validation

#### 4.1 Test Database Connectivity

```bash
# From one of your application servers
mysql -h <mysql-ec2-private-ip> -u <username> -p<password> -e "SELECT 1;"
```

#### 4.2 Test Application Functionality

1. Deploy the updated application configuration to a test environment
2. Verify all CRUD operations work correctly
3. Check performance metrics and response times
4. Run load tests to ensure the new database can handle the expected traffic

### 5. Cutover Plan

#### 5.1 Pre-Cutover Tasks

1. Schedule a maintenance window with minimal user impact
2. Notify all stakeholders about the planned migration
3. Prepare rollback procedures in case of issues
4. Ensure all application servers have the updated configuration ready

#### 5.2 Cutover Steps

1. Put the application in maintenance mode
2. Perform a final data sync from Aurora to MySQL
3. Update all application servers with the new database configuration
4. Restart application services
5. Take the application out of maintenance mode
6. Monitor application and database performance closely

#### 5.3 Post-Cutover Tasks

1. Verify all functionality is working correctly
2. Monitor database performance and resource utilization
3. Optimize MySQL configuration if needed
4. Keep Aurora as a backup for 1-2 weeks before decommissioning

### 6. Rollback Plan

If issues are encountered during or after the migration:

1. Revert application configuration to use Aurora
2. Restart application services
3. Verify functionality with Aurora
4. Investigate and resolve issues with the MySQL setup

### 7. Cost Optimization Considerations

- Choose the appropriate EC2 instance type based on your database workload
- Consider using Reserved Instances for long-term cost savings
- Monitor resource utilization and adjust instance size as needed
- Implement automated backups to S3 for cost-effective storage
- Use CloudWatch alarms to monitor and optimize resource usage

### 8. Security Considerations

- Ensure the MySQL container is configured with appropriate security settings
- Use encrypted EBS volumes for data storage
- Implement regular security patching for the EC2 instance and MySQL
- Configure database users with least privilege access
- Use VPC security groups to restrict access to the database

## Conclusion

This migration will reduce costs by replacing Aurora with a containerized MySQL solution while maintaining application functionality. The containerized approach provides flexibility for future scaling and management while the dedicated EC2 instance ensures predictable performance.

Monitor the new setup closely after migration and be prepared to make adjustments to configuration as needed to optimize performance and cost.