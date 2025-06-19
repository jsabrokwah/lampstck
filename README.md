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
- **Database**: Containerized MySQL on EC2 with EBS storage
- **Infrastructure**: AWS CloudFormation for automated infrastructure provisioning and stack deployment

## AWS Infrastructure Integration

This application is designed to work with the following AWS infrastructure components:

- **Load Balancing**: Application Load Balancer distributes traffic across multiple EC2 instances
- **Auto Scaling**: EC2 instances in private subnets with Auto Scaling Groups for elasticity
- **Database**: Containerized MySQL on dedicated EC2 instance in isolated subnet with EBS-backed persistent storage
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

## Deployment Instructions

Use the included CloudFormation template (`cloudformation-template.yaml`) for fully automated infrastructure deployment. See [implementation-journey.md](implementation-journey.md) for detailed steps.