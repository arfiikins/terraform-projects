# Building a 3-tier web application architecture with AWS (Aalok T's design)
![three-tier-arch](https://miro.medium.com/v2/resize:fit:720/format:webp/1*qtoXNNXzBKuVvxFIqCojPg.png)

## The underlying network architecture
- A VPC.
- Two (2) public subnets spread across two availability zones (Web Tier).
- Two (2) private subnets spread across two availability zones (Application Tier).
- Two (2) private subnets spread across two availability zones (Database Tier).
- One (1) public route table that connects the public subnets to an internet gateway.
- One (1) private route table that will connect the Application Tier private subnets and a NAT gateway.

## Tier 1: Web tier (Frontend)
1. Web server launch instance using EC2 instance
2. ASG
3. ALB

## Tier 2: Application tier (Backend)
1. Web server launch instance using EC2 instance
2. ASG
3. ALB
4. Bastion host to do an ssh

## Tier 3: Database tier (Data storage & retrieval)
Build the following:
1. DB Security Group
2. DB Subnet Group
3. RDS database

Project reference guide: https://medium.com/@aaloktrivedi/building-a-3-tier-web-application-architecture-with-aws-eb5981613e30