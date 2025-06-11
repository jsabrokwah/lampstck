# Todo Application for LAMP Stack

A simple Todo application designed to be deployed on a highly available LAMP stack infrastructure in AWS, following AWS Well-Architected Framework principles.

## Live Application

[Click Here To Access The Live Application](http://todo-a-appli-z32xkrdnjixv-570804106.eu-west-1.elb.amazonaws.com/)

## Features

- Create, read, update, and delete todo items
- Mark todos as complete/incomplete
- Responsive design for mobile and desktop
- Secure data handling with input validation
- High availability across multiple Availability Zones

## Technical Stack

- **Frontend**: HTML, CSS, JavaScript
- **Backend**: PHP
- **Database**: Aurora MySQL in AWS
- **Infrastructure**: AWS CloudFormation for automated deployment

## Deployment Instructions

### Database Setup

1. Connect to your MySQL database:
   ```
   mysql -u root -p
   ```

2. Run the setup script:
   ```
   mysql -u root -p < setup.sql
   ```

### Application Deployment

1. Deploy the application files to your web server document root:
   ```
   cp -r * /var/www/html/
   ```

2. Update the database configuration in `api/config.php` with your Aurora MySQL endpoint and credentials.

3. Set proper permissions:
   ```
   chmod -R 755 /var/www/html/
   chown -R apache:apache /var/www/html/
   ```

## AWS Infrastructure Integration

This application is designed to work with the following AWS infrastructure components:

- **Load Balancing**: Application Load Balancer distributes traffic across multiple EC2 instances
- **Auto Scaling**: EC2 instances in private subnets with Auto Scaling Groups for elasticity
- **Database**: Aurora MySQL in isolated subnets with primary and replica instances for high availability
- **Security**: Network ACLs, Security Groups, and IAM roles for defense in depth
- **Monitoring**: CloudWatch for performance metrics and operational visibility

## Security Considerations

- Input validation and sanitization for all user inputs
- Prepared statements to prevent SQL injection
- Private subnets for application servers with no direct internet access
- Isolated subnets for database instances
- Security groups for fine-grained access control

## Monitoring and Operations

The application includes CloudWatch integration for:

- CPU and memory utilization metrics
- Disk usage monitoring
- HTTP request tracking
- Custom dashboard for operational visibility
- Automated scaling based on demand

## Automated Deployment

Use the included CloudFormation template (`cloudformation-template.yaml`) for fully automated infrastructure deployment. See `deployment-instructions.md` for detailed steps.