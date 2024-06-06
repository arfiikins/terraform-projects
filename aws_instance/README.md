Deploy the following:
1. VPC
2. Two subnets (public and private) => public subnet is connected to IGW while private subnet have no external connections
3. Routing table to route the internet traffic to 0.0.0.0/0 (the target is the internet gateway)
4. Associate the route tables with the public subnet
5. Create a Security Group to allow inbound: ssh on public cidr block and HTTPS and HTTP on internet and outbound: any
6. Create a network interface and associate the Security Group and Public Subnet
7. Assign an Elastic IP to the network interface of step 6, and associate it to the public instance.
8. Provisioned an Ubuntu Server and install/enabled apache2
9. Outputs the public ip and instance id
