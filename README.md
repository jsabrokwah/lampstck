# Todo Application for LAMP Stack

A simple Todo application designed to be deployed on a LAMP stack infrastructure with high availability.

## Features

- Create, read, update, and delete todo items
- Mark todos as complete/incomplete
- Responsive design for mobile and desktop

## Technical Stack

- **Frontend**: HTML, CSS, JavaScript
- **Backend**: PHP
- **Database**: MySQL (Aurora MySQL in AWS)

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
   cp -r todoApp/* /var/www/html/
   ```

2. Update the database configuration in `api/config.php` with your Aurora MySQL endpoint and credentials.

3. Set proper permissions:
   ```
   chmod -R 755 /var/www/html/
   chown -R www-data:www-data /var/www/html/
   ```

## AWS Infrastructure Integration

This application is designed to work with the following AWS infrastructure components:

- **Load Balancing**: Application Load Balancer distributes traffic across multiple EC2 instances
- **Auto Scaling**: EC2 instances in private subnets with Auto Scaling Groups
- **Database**: Aurora MySQL in isolated subnets with primary and replica instances
- **Content Delivery**: CloudFront for static asset caching
- **Security**: WAF for protection against common web exploits

## Security Considerations

- Input validation and sanitization for all user inputs
- Prepared statements to prevent SQL injection
- HTTPS for secure data transmission
- WAF rules to protect against common attacks

## Monitoring

The application can be monitored using CloudWatch with custom metrics for:

- API endpoint response times
- Database query performance
- Error rates
- User activity