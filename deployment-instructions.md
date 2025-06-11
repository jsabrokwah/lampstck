# Deployment Instructions for Todo App Infrastructure

This document provides comprehensive step-by-step instructions for deploying the Todo application infrastructure using AWS CloudFormation, ensuring high availability, security, and adherence to AWS Well-Architected Framework principles.

## Prerequisites

1. AWS CLI installed and configured with appropriate credentials
2. An EC2 key pair for SSH access to instances
3. Basic understanding of AWS services (EC2, VPC, RDS, CloudFormation)

## Step 1: Prepare for Deployment

Before deploying the infrastructure:

1. Review the CloudFormation template (`cloudformation-template.yaml`) to understand the resources that will be created:
   - VPC with public, private, and isolated subnets across two Availability Zones
   - Application Load Balancer in public subnets
   - EC2 instances in private subnets with Auto Scaling
   - Aurora MySQL database in isolated subnets
   - Security groups, IAM roles, and CloudWatch monitoring

2. Update the repository URL in the CloudFormation template if you're hosting the code in your own repository:
   - Locate the `UserData` section in the `WebServerLaunchTemplate` resource
   - Replace the GitHub repository URL with your own if needed

## Step 2: Deploy the CloudFormation Stack

1. Create an S3 bucket for the CloudFormation template (optional for large templates):
   ```bash
   aws s3 mb s3://your-cloudformation-bucket
   aws s3 cp cloudformation-template.yaml s3://your-cloudformation-bucket/
   ```

2. Deploy the CloudFormation stack:
   ```bash
   aws cloudformation create-stack \
     --stack-name todo-app-stack \
     --template-body cloudformation-template.yaml \
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

1. Get the database endpoint:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name todo-app-stack \
     --query "Stacks[0].Outputs[?OutputKey=='DatabaseEndpoint'].OutputValue" \
     --output text
   ```

2. Connect to one of the EC2 instances using AWS Systems Manager Session Manager:
   ```bash
   # Get an instance ID from the Auto Scaling Group
   aws ec2 describe-instances \
     --filters "Name=tag:aws:autoscaling:groupName,Values=todo-app-ASG" \
     --query "Reservations[0].Instances[0].InstanceId" \
     --output text
   
   # Connect using Session Manager (more secure than SSH)
   aws ssm start-session --target <instance-id>
   ```

3. Verify the database tables were created:
   ```bash
   mysql -h <database-endpoint> -u admin -p -e "USE todo_app; SHOW TABLES;"
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
   aws cloudformation describe-stacks \
     --stack-name todo-app-stack \
     --query "Stacks[0].Outputs[?OutputKey=='WebAppDashboard'].OutputValue" \
     --output text
   ```

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

3. Use the included `fix-lamp-stack.sh` script to repair common configuration issues:
   ```bash
   ./fix-lamp-stack.sh
   ```

## Cleanup

To delete the entire infrastructure when no longer needed:

```bash
aws cloudformation delete-stack --stack-name todo-app-stack
```

This will delete all resources created by the CloudFormation stack, including the VPC, EC2 instances, load balancer, and Aurora database cluster.