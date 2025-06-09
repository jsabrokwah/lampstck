# Infrastructure Architecture Plan for LAMP stack Todo Application with high availability, security and adhere to Well Architected Framework

## Architecture Overview

```
                                   ┌──────────-──────────┐
                                   │   CloudFront CDN    │
                                   └──────────┬──────────┘
                                              │
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

## Architecture for Todo Application with High Traffic and Security Focus

### 1. VPC and Network Design
- **Multi-AZ VPC**: Spanning two Availability Zones (AZ-A and AZ-B) for high availability
- **Subnet Tiers**:
  - **Public Subnets**: Only for Application Load Balancer and NAT Gateways
  - **Private Subnets**: For LAMP stack EC2 instances
  - **Isolated Subnets**: For database instances with no internet access
- **Network Security**:
  - **Network ACLs (NACLs)**:
    - Public subnet NACLs: Allow HTTP/HTTPS inbound, restrict outbound to necessary ports
    - Private subnet NACLs: Allow traffic from ALB and outbound to NAT Gateway
    - Isolated subnet NACLs: Allow only database traffic from private subnets
  - Security Groups for instance-level security
  - VPC Flow Logs for network traffic monitoring
- **NAT Gateways**:
  - Deployed in each public subnet (AZ-A and AZ-B)
  - Enables EC2 instances in private subnets to access the internet for updates and patches
  - Provides high availability with one NAT Gateway per AZ

### 2. Frontend and Content Delivery
- **Amazon CloudFront**: 
  - Edge caching for static assets (CSS, JS, images)
  - Custom error responses for maintenance pages
  - Origin Access Identity to prevent direct access to S3

### 3. Security and Access Control
- **AWS WAF**: Integrated with CloudFront and ALB
  - Rate limiting to prevent brute force attacks
  - SQL injection protection rules

### 4. Load Balancing and Traffic Management
- **Application Load Balancer**:
  - Deployed in public subnets
  - HTTP to HTTPS redirection
  - Advanced routing based on paths (/api/~)
  - Sticky sessions for authenticated users
  - Connection draining during deployments

### 5. Compute Layer (Optimized for Todo App)
- **LAMP Stack Instances**:
  - Apache and PHP on the same EC2 instances for reduced latency
  - Deployed in private subnets for security
  - Auto Scaling Groups in both AZ-A and AZ-B
  - Predictive scaling based on time patterns (e.g., business hours)
  - Manual deployment process for application updates
- **EC2 Instance Type**: t2.micro


### 6. Database Layer
- **Amazon Aurora MySQL**:
  - Deployed in isolated subnets
  - Multi-AZ deployment with primary and replica instances
  - Performance Insights enabled for query optimization
  - Automated backups with 35-day retention
  - Point-in-time recovery capability

### 7. Security and Access Management
- **Security Controls**:
  - Security groups for instance-level access control
  - Network ACLs for subnet-level security
  - IAM roles and policies for AWS service access
  - Encryption for data at rest and in transit

### 8. Monitoring and Operations
- **CloudWatch**:
  - Custom dashboard for todo application metrics
  - Anomaly detection for unusual traffic patterns
  - Synthetic canary testing for critical paths
