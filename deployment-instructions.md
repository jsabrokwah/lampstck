# Deployment Instructions for Todo App Infrastructure

This guide provides step-by-step instructions for deploying the Todo application infrastructure using AWS CloudFormation.

## Prerequisites

1. AWS CLI installed and configured with appropriate credentials
2. An EC2 key pair for SSH access to instances
3. The Todo application code (from the `todoApp` directory)

## Step 1: Prepare the Application Code

Before deploying the infrastructure, you need to make the application code available:

1. Create a GitHub repository for your Todo application:
   ```bash
   cd todoApp
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/todo-app.git
   git push -u origin main
   ```

2. Update the CloudFormation template with your GitHub repository URL:
   - Open `cloudformation-template.yaml`
   - Find the `UserData` section in the `WebServerLaunchTemplate` resource
   - Replace `https://github.com/yourusername/todo-app.git` with your actual repository URL

## Step 2: Deploy the CloudFormation Stack

1. Create an S3 bucket to store the CloudFormation template (optional for large templates):
   ```bash
   aws s3 mb s3://your-cloudformation-bucket
   aws s3 cp cloudformation-template.yaml s3://your-cloudformation-bucket/
   ```

2. Deploy the CloudFormation stack:
   ```bash
   aws cloudformation create-stack \
     --stack-name todo-app-stack \
     --template-file cloudformation-template.yaml \
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

## Step 3: Initialize the Database

After the stack is created successfully, you need to initialize the database:

1. Get the database endpoint:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name todo-app-stack \
     --query "Stacks[0].Outputs[?OutputKey=='DatabaseEndpoint'].OutputValue" \
     --output text
   ```

2. Connect to one of the EC2 instances using Session Manager or SSH:
   ```bash
   # First, get the instance ID
   aws ec2 describe-instances \
     --filters "Name=tag:aws:autoscaling:groupName,Values=todo-app-ASG" \
     --query "Reservations[0].Instances[0].InstanceId" \
     --output text
   
   # Then connect using SSH (if your security group allows)
   ssh -i your-key-pair.pem ec2-user@<instance-public-ip>
   
   # Or use Session Manager
   aws ssm start-session --target <instance-id>
   ```

3. Run the database setup script:
   ```bash
   mysql -h <database-endpoint> -u admin -p < /var/www/html/setup.sql
   ```

## Step 4: Verify the Deployment

1. Get the website URL:
   ```bash
   aws cloudformation describe-stacks \
     --stack-name todo-app-stack \
     --query "Stacks[0].Outputs[?OutputKey=='WebsiteURL'].OutputValue" \
     --output text
   ```

2. Open the URL in your browser to verify that the Todo application is working correctly.

## Step 5: Set Up CloudFront (Optional)

For better performance and security, you can set up CloudFront to serve your application:

1. Create a CloudFront distribution:
   ```bash
   aws cloudfront create-distribution \
     --origin-domain-name <alb-dns-name> \
     --default-root-object index.php
   ```

2. Update your application to use CloudFront URLs for static assets.

## Monitoring and Maintenance

- **CloudWatch Dashboards**: The CloudFormation template sets up basic CloudWatch alarms for CPU utilization. You can create additional dashboards for monitoring.

- **Backups**: Database backups are automatically configured with a 35-day retention period. Application backups can be stored in the created S3 bucket.

- **Scaling**: The Auto Scaling Group will automatically scale based on CPU utilization. You can adjust the scaling policies as needed.

## Cleanup

To delete the entire infrastructure when no longer needed:

```bash
aws cloudformation delete-stack --stack-name todo-app-stack
```

This will delete all resources created by the CloudFormation stack, including the VPC, EC2 instances, load balancer, and Aurora database cluster.