provider "aws" {                                            # First is to define the provider
  region = "us-west-1"                                      # Select a region (N. Cali)

}

variable "access_secret_keys" {
  description = "input the access key you will be using"
}
variable "subnet_prefix" {
  description = "cidr block for the public subnet"
  default = "10.10.1.0/24"

}

variable "key_pair" {
  description = "my key pair to access the EC2 instance"
}

# 1. Create VPC
resource "aws_vpc" "myVpc" {
    cidr_block = "10.10.0.0/16"
    tags = {
        Name = "jana-myVpc"
    }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "myIgw" {
  vpc_id = aws_vpc.myVpc.id
  tags = {
    Name = "jana-myIgw"
  }
}

# 3. Create Custom Route Table
resource "aws_route_table" "myPublicRouteTable" {
  vpc_id = aws_vpc.myVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIgw.id
  }

  tags = {
    Name = "jana-myPublicRouteTable"
  }
}

# 4. Create a Subnet
resource "aws_subnet" "publicSubnet" {
  cidr_block = var.subnet_prefix[0].subnet
  vpc_id = aws_vpc.myVpc.id
  availability_zone = "us-west-1a"
  
  tags = {
    Name = var.subnet_prefix[0].name
  }
}

resource "aws_subnet" "privateSubnet" {
  cidr_block = var.subnet_prefix[1].subnet
  vpc_id = aws_vpc.myVpc.id
  availability_zone = "us-west-1a"

  tags = {
    Name = var.subnet_prefix[1].name
  }
}

# 5. Associate subnet with Route Tables
resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.publicSubnet.id
  route_table_id = aws_route_table.myPublicRouteTable.id
}

# 6. Create Security Group to allow port 22, 80, 443
resource "aws_security_group" "mySecurityGroup" {
  name = "mySecurityGroup"
  description = "Allow inbound SSH access"
  vpc_id = aws_vpc.myVpc.id

  ingress {
    description   = "SSH from my vpc cidr block"
    from_port     = 22
    to_port       = 22
    protocol   = "tcp"
    cidr_blocks    = ["10.10.0.0/16"]
  }

  ingress {
    description   = "HTTPS from anywhere"
    from_port     = 443
    to_port       = 443
    protocol   = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
  }
  
  ingress {
    description   = "HTTP from anywhere"
    from_port     = 80
    to_port       = 80
    protocol   = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
  }

  egress {
    description   = "allow_all"
    from_port     = 0
    to_port       = 0
    protocol   = "-1"
    cidr_blocks    = ["0.0.0.0/0"]
  }


  tags = {
    Name = "jana-mySecurityGroup"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step4
resource "aws_network_interface" "myNetworkInterface" {
  subnet_id = aws_subnet.publicSubnet.id
  # private_ips = [ "10.10.1.5" ]
  security_groups = [aws_security_group.mySecurityGroup.id]

}

# 8. Assign an elastic IP to the network interface created in step7
resource "aws_eip" "myPublicInstancEip" {
  domain = "vpc"
  # vpc = true
  network_interface = aws_network_interface.myNetworkInterface.id
  associate_with_private_ip = aws_instance.myPublicInstance.private_ip
  depends_on = [ aws_internet_gateway.myIgw ]
}


# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "myPublicInstance" {
  ami             = "ami-08012c0a9ee8e21c4"                 # Ubuntu 24.04
  instance_type   = "t2.small"
  availability_zone = "us-west-1a"
  key_name        = var.key_pair
  
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.myNetworkInterface.id
  }
  
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y apache2
              sudo systemctl enable apache2
              sudo systemctl start apache2
              sudo bash -c 'echo your very first server > /var/www/html/index.html'
              EOF

  tags = {
    Name = "jana-deployedUsingTerraform"
    Shift = "ANZ-Shift"
  }
}

output "server-public-ip" {
  value = aws_instance.myPublicInstance.public_ip
}

output "id" {
  value = aws_instance.myPublicInstance.id
}