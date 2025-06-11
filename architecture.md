# Infrastructure Architecture Plan for LAMP Stack Todo Application

This document details the infrastructure architecture for a highly available, secure LAMP stack Todo application that adheres to AWS Well-Architected Framework principles.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────-┐
│                                      AWS VPC                                             │
│                                                                                          │
│  ┌─────────────────────────────────┐     ┌───────▼────────┐     ┌─────────────────────┐  │
│  │      Public Subnet (AZ-A)       │     │ Application    │     │ Public Subnet (AZ-B)│  │
│  │                                 │     │ Load Balancer  │     │                     │  │
│  │                                 │     │ with WAF       │     │                     │  │
│  └─────────────┬───────────────────┘     └───────┬────────┘     └┬────────────────────┘  │
│                │                                 │               │                       │
│                ▼                                 │               ▼                       │
│  ┌─────────────────────┐                         │ ┌─────────────────────┐               │
│  │ Private Subnet (AZ-A)│                        │ │Private Subnet (AZ-B)│               │
│  │                     │                         │ │                     │               │
│  │  ┌─────────────┐    │                         │ │  ┌─────────────┐    │               │
│  │  │ Auto Scaling│    │                         │ │  │ Auto Scaling│    │               │
│  │  │ LAMP Stack  │    │                         │ │  │ LAMP Stack  │    │               │
│  │  │ (Apache+PHP)│    │                         │ │  │ (Apache+PHP)│    │               │ 
│  │  └─────┬───────┘    │                         │ │  └─────┬───────┘    │               │
│  │        │            │                         │ │        │            │               │
│  └────────┼────────────┘                         │ └────────┼────────────┘               │ 
│           │                                      │          │                            │
│           ▼                                      │          ▼                            │
│  ┌────────────────────┐                          │ ┌────────────────────┐                │
│  │ Isolated Subnet    │                          │ │ Isolated Subnet    │                │
│  │ (AZ-A)             │                          │ │ (AZ-B)             │                │
│  │                    │                          │ │                    │                │
│  │  ┌────────────┐    │                          │ │  ┌────────────┐    │                │
│  │  │ Aurora     │◄─────────────────────────────────┤ │ Aurora     │    │                │
│  │  │ MySQL      │    │                          │ │  │ MySQL      │    │                │
│  │  │ Primary    │    │                          │ │  │ Replica    │    │                │
│  │  └────────────┘    │                          │ │  └────────────┘    │                │
│  └────────────────────┘                          │ └────────────────────┘                │
│                                                  │                                       │
└──────────────────────────────────────────────────┼──────────────────────────────────────-┘
                                                   │
                      ┌────────────────────────────┴───────────┐
                      │                                        │
              ┌────────▼────────┐                      ┌────────▼────────┐
              │  S3 Buckets     │                      │  CloudWatch     │
              │  (Backups)      │                      │  (Monitoring)   │
              └─────────────────┘                      └─────────────────┘
```

## Well-Architected Framework Implementation

This architecture addresses the five pillars of the AWS Well-Architected Framework:

1. **Operational Excellence**: Automated deployment via CloudFormation, comprehensive monitoring, and operational procedures
2. **Security**: Defense in depth with network segmentation, least privilege access, and encryption
3. **Reliability**: Multi-AZ deployment, auto-scaling, and automated failover
4. **Performance Efficiency**: Right-sized resources with ability to scale based on demand
5. **Cost Optimization**: Pay-for-use model with auto-scaling to match resource consumption with demand

## Architecture Components and Design Decisions

### 1. VPC and Network Design
- **Multi-AZ VPC**: Spans two Availability Zones (AZ-A and AZ-B) for high availability and fault tolerance
- **Subnet Tiers**:
  - **Public Subnets**: Host only the Application Load Balancer and NAT Gateways
  - **Private Subnets**: Contain LAMP stack EC2 instances with no direct internet access
  - **Isolated Subnets**: House database instances with no outbound internet access
- **Network Security**:
  - **Network ACLs**: Provide subnet-level security with stateless filtering
  - **Security Groups**: Offer instance-level security with stateful filtering
  - **VPC Flow Logs**: Enable network traffic monitoring and troubleshooting
- **NAT Gateways**: Allow EC2 instances in private subnets to access the internet for updates while maintaining security

### 2. Load Balancing and Traffic Management
- **Application Load Balancer**:
  - Distributes traffic across multiple EC2 instances in different AZs
  - Performs health checks to ensure traffic is only sent to healthy instances
  - Supports connection draining during deployments for zero-downtime updates
  - Integrates with AWS WAF for additional security

### 3. Compute Layer
- **Auto Scaling Groups**:
  - Maintain application availability by ensuring minimum number of healthy instances
  - Scale horizontally based on CPU utilization and request patterns
  - Span multiple AZs for high availability
  - Use Launch Templates for consistent instance configuration
- **EC2 Instances**:
  - Run Amazon Linux 2023 for improved security and performance
  - Host Apache web server and PHP runtime environment
  - Deployed in private subnets for enhanced security
  - Configured with CloudWatch agent for detailed monitoring

### 4. Database Layer
- **Amazon Aurora MySQL**:
  - Provides high availability with automatic failover to replica instances
  - Deployed across multiple AZs for disaster recovery
  - Offers automated backups with 35-day retention period
  - Enables point-in-time recovery for data protection
  - Uses isolated subnets for maximum security

### 5. Security Implementation
- **Defense in Depth**:
  - Network segmentation with public, private, and isolated subnets
  - Security groups for fine-grained access control
  - IAM roles for EC2 instances with least privilege permissions
  - Encryption for data at rest and in transit
- **Application Security**:
  - Input validation and sanitization in the application code
  - Prepared statements to prevent SQL injection
  - Secure coding practices throughout the application

### 6. Monitoring and Operations
- **CloudWatch Integration**:
  - Custom dashboard for application and infrastructure metrics
  - Alarms for critical thresholds (CPU, memory, disk usage)
  - Log aggregation for troubleshooting and analysis
  - Automated scaling triggers based on performance metrics

### 7. Backup and Recovery
- **Data Protection**:
  - Automated database backups with 35-day retention
  - S3 bucket for application backups and artifacts
  - Multi-AZ deployment for infrastructure resilience
  - Documented recovery procedures

## Implementation Details

This architecture is implemented using AWS CloudFormation for infrastructure as code, ensuring consistent, repeatable deployments. The CloudFormation template (`cloudformation-template.yaml`) provisions all required resources and configures them according to best practices.

For detailed deployment instructions, refer to the `deployment-instructions.md` document.
