# Project Implementation and Deployment Instructions for Lamp Stack (Todo App) Infrastructure

This document provides comprehensive step-by-step instructions for deploying the Todo application infrastructure using AWS CloudFormation, ensuring high availability, security, and adherence to AWS Well-Architected Framework principles.

## Prerequisites

1. AWS CLI installed and configured with appropriate credentials
2. An EC2 key pair for SSH access to instances
3. Basic understanding of AWS services (EC2, VPC, Elastic Load Balancer, Security Group, CloudFormation, CloudWatch, IAM Roles), Docker, SQL Database, PHP, HTML, CSS, Javascript, and Apache
4. A git repository with this entire project files pushed into it's main branch

## Step 1: Prepare for Deployment

Before deploying the infrastructure:

1. Review the CloudFormation template (`cloudformation-template.yaml`) to understand the resources that will be created:
   - VPC with public, private, and isolated subnets across two Availability Zones
   - Application Load Balancer in public subnets
   - EC2 instances in private subnets with Auto Scaling
   - Containerized MySQL database on EC2 in isolated subnet
   - Security groups, IAM roles, and CloudWatch monitoring
   - Review the User Data UserData in the `WebServerLaunchTemplate` and `MySQLDBInstance` blocks to understand the scripts and commands that get executed when an instance is launched

2. Update the git repository URL in the CloudFormation template if you're hosting the code in your own git repository:
   - Locate the `UserData` section in the `WebServerLaunchTemplate` resource
   - Replace the GitHub repository URL with your own if needed

## Step 2: Deploy the CloudFormation Stack

1. Validate the cloudformation-template.yaml to review how the infrastructure will be provisioned. You'd also see any error should any occur
   ```bash
   aws cloudformation validate-template --template-body file://cloudformation-template.yaml
   ```

2. Create an S3 bucket for the CloudFormation template (optional if you'd like to deploy from S3 bucket):
   ```bash
   aws s3 mb s3://your-cloudformation-bucket
   aws s3 cp cloudformation-template.yaml s3://your-cloudformation-bucket/
   ```

3. Deploy the CloudFormation stack (from your local machine):
   ```bash
   aws cloudformation create-stack \
     --stack-name todo-app-stack \
     --template-body file://cloudformation-template.yaml \
     --parameters \
       ParameterKey=KeyName,ParameterValue=your-key-pair-name \
       ParameterKey=DBPassword,ParameterValue=your-secure-password \
     --capabilities CAPABILITY_IAM
   ```

   Alternatively, if you uploaded the template to S3:
   ```bash
   aws cloudformation create-stack \
     --stack-name todo-app-stack \
     --template-url https://your-cloudformation-bucket.s3.amazonaws.com/cloudformation-template.yaml \
     --parameters \
       ParameterKey=KeyName,ParameterValue=your-key-pair-name \
       ParameterKey=DBPassword,ParameterValue=your-secure-password \
     --capabilities CAPABILITY_IAM
   ```

3. Monitor the stack creation:
   ```bash
   aws cloudformation describe-stacks --stack-name todo-app-stack
   ```

   The deployment process will take approximately 10-15 minutes to complete as it creates all the necessary infrastructure components.

## Step 3: Verify Database Initialization

The CloudFormation template includes user data scripts that automatically initialize the database. To verify:

1. Get the MySQL database endpoint (private IP):
   ```bash
   aws cloudformation describe-stacks \
     --stack-name todo-app-stack \
     --query "Stacks[0].Outputs[?OutputKey=='MySQLEndpoint'].OutputValue" \
     --output text
   ```

2. Connect to the MySQL database EC2 instance using AWS Systems Manager Session Manager:
   ```bash
   # Get the MySQL database instance ID
   aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=todo-app-MySQL-DB-Server" \
     --query "Reservations[0].Instances[0].InstanceId" \
     --output text
   
   # Connect using Session Manager
   aws ssm start-session --target <mysql-instance-id>
   ```

3. Verify the MySQL container and database tables:
   ```bash
   # Check if MySQL container is running
   sudo docker ps | grep mysql-server
   
   # Connect to MySQL container and verify tables
   sudo docker exec -it mysql-server mysql -u admin -p -e "USE todo_app; SHOW TABLES;"
   ```

## Step 4: Access and Test the Application

1. Get the website URL from the CloudFormation outputs:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name todo-app-stack \
     --query "Stacks[0].Outputs[?OutputKey=='WebsiteURL'].OutputValue" \
     --output text
   ```

2. Open the URL in your browser to verify that the Todo application is working correctly:
   - Create new todo items
   - Mark items as complete
   - Delete items
   - Verify that data persists when refreshing the page

## Step 5: Security and Performance Enhancements

For production environments, consider these additional enhancements:

1. Enable HTTPS by adding an SSL/TLS certificate to the Application Load Balancer:
   ```bash
   # Create a certificate in AWS Certificate Manager
   aws acm request-certificate --domain-name yourdomain.com --validation-method DNS
   
   # Add HTTPS listener to the ALB (after certificate validation)
   aws elbv2 create-listener \
     --load-balancer-arn <alb-arn> \
     --protocol HTTPS \
     --port 443 \
     --certificates CertificateArn=<certificate-arn> \
     --default-actions Type=forward,TargetGroupArn=<target-group-arn>
   ```

2. Set up CloudFront for content delivery and additional security:
   ```bash
   aws cloudfront create-distribution \
     --origin-domain-name <alb-dns-name> \
     --default-root-object index.php
   ```

## Monitoring and Operations

The deployment includes built-in monitoring through CloudWatch:

1. Access the CloudWatch dashboard:
   ```bash
   # Dashboard is available in AWS Console under CloudWatch > Dashboards
   # Dashboard name: <EnvironmentName>-Dashboard (e.g., todo-app-Dashboard)
   aws cloudwatch get-dashboard --dashboard-name todo-app-Dashboard
   ```
   You can equally access the dashboard through the management console for visualized dashboard

2. Key metrics being monitored:
   - EC2 CPU utilization (triggers auto-scaling)
   - Memory usage
   - Disk space utilization
   - Application Load Balancer request counts
   - Database connections and performance

3. Logs are automatically collected for:
   - Apache access and error logs
   - System logs
   - Application errors

## Troubleshooting

If you encounter issues with the deployment:

1. Check the CloudFormation events for error messages:
   ```bash
   aws cloudformation describe-stack-events --stack-name todo-app-stack
   ```

2. Examine EC2 instance logs using Systems Manager:
   ```bash
   aws ssm start-session --target <instance-id>
   sudo cat /var/log/user-data.log
   sudo cat /var/log/httpd/error_log
   ```

3. If Add todo action from the frontend fails:
   i) ssm into any of the todo-app-WebServer instances
   ii) Run the following commands:
      ```bash
         cd /var/www/html
         # Verify the database can be connected from the WebServer Instance
         sudo mysql -h <MySQLEndpoint> -u <MySQLUsername> -D <MySQLDBName> -p<MySQLPassword>  #Get the parameters from the Outputs tab cloudformation dashboard
         # If the connection can be established, exit the mysql session, then run the command below to recreate the tables:
         sudo mysql -h <MySQLEndpoint> -u <MySQLUsername> -D <MySQLDBName> -p<MySQLPassword> < setup.sql

## Security and Performance Testing

### Security Testing

1. **Network Security Validation**:
   ```bash
   # Test that containerized MySQL is not accessible from public internet
   nmap -p 3306 <mysql-ec2-private-ip>  # Should show filtered/closed from external
   
   # Verify MySQL container security
   sudo docker exec mysql-server netstat -tlnp | grep 3306  # Should only bind to container
   
   # Verify web servers are only accessible through ALB
   nmap -p 80,443 <web-server-private-ip>  # Should timeout from external
   ```

2. **Application Security Testing**:
   ```bash
   # Test SQL injection protection
   curl -X POST "http://<alb-dns>/api/add_todo.php" \
     -d "task='; DROP TABLE todos; --"
   
   # Verify input sanitization
   curl -X POST "http://<alb-dns>/api/add_todo.php" \
     -d "task=<script>alert('xss')</script>"
   ```

### Performance Testing

1. **Load Testing with Apache Bench**:
   ```bash
   # Install Apache Bench
   sudo yum install -y httpd-tools
   
   # Test concurrent requests
   ab -n 1000 -c 10 http://<alb-dns>/
   
   # Test API endpoints
   ab -n 500 -c 5 -p post_data.txt -T application/x-www-form-urlencoded \
     http://<alb-dns>/api/get_todos.php
   ```

2. **Monitor Auto Scaling**:
   ```bash
   # Generate load to trigger scaling
   ab -n 10000 -c 50 http://<alb-dns>/
   
   # Watch scaling events
   aws autoscaling describe-scaling-activities \
     --auto-scaling-group-name <asg-name>
   ```

## Cleanup

To delete the entire infrastructure when no longer needed:

```bash
aws cloudformation delete-stack --stack-name todo-app-stack
```

This will delete all resources created by the CloudFormation stack, including the VPC, EC2 instances, load balancer, and containerized MySQL database.