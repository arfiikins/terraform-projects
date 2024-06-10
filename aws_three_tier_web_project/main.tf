provider "aws" {
  region = "us-west-1"
}

#======================================================================#
#===============================VARIABLES==============================#
#======================================================================#
variable "project_name" {
  description = "Input your project name identifier"
}
variable "vpc_cidr_block" {
  description = "This will indicate the cidr block of your VPC"
}
variable "subnet_cidr_blocks" {
  description = "This will be the list of cidr blocks for your subnets" # [0] = Public Subnet 1; [1] = Public Subnet 2; ... ; [6] = Private Subnet 4
}
variable "availability_zones" {
  description = "This will be list of availability zones for the current region"
}
variable "key_name" {
  description = "This will be the key name"
  default = "webserver_kp"
}
data "aws_security_group" "appserver_existing_sg" {
  id = aws_security_group.appserver_sg.id
}

#======================================================================#
#===============================RESOURCES==============================#
#======================================================================#
# Deploy Networking: 1 Region (us-west-1), 1 VPC, 3 Subnets per AZ
resource "aws_vpc" "vpc_production" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public Subnets (Web Servers)
resource "aws_subnet" "web_public_subnet_1a" { # us-west-1a
  vpc_id                  = aws_vpc.vpc_production.id
  availability_zone       = var.availability_zones[0]
  cidr_block              = var.subnet_cidr_blocks[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-web-pub-1a"
  }
}

resource "aws_subnet" "web_public_subnet_1c" { # us-west-1c        
  vpc_id                  = aws_vpc.vpc_production.id
  availability_zone       = var.availability_zones[1]
  cidr_block              = var.subnet_cidr_blocks[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-web-pub-1c"
  }
}

# Private Subnets (Application instances)
resource "aws_subnet" "app_private_subnet_1a" { # us-west-1a
  vpc_id            = aws_vpc.vpc_production.id
  availability_zone = var.availability_zones[0]
  cidr_block        = var.subnet_cidr_blocks[2]

  tags = {
    Name = "${var.project_name}-app-priv-1a"
  }
}

resource "aws_subnet" "app_private_subnet_1c" { # us-west-1c
  vpc_id            = aws_vpc.vpc_production.id
  availability_zone = var.availability_zones[1]
  cidr_block        = var.subnet_cidr_blocks[3]

  tags = {
    Name = "${var.project_name}-app-priv-1c"
  }
}

# Private Subnets (Database instances)
resource "aws_subnet" "rds_private_subnet_1a" { # us-west-1a
  vpc_id            = aws_vpc.vpc_production.id
  availability_zone = var.availability_zones[0]
  cidr_block        = var.subnet_cidr_blocks[4]

  tags = {
    Name = "${var.project_name}-rds-priv-1a"
  }
}

resource "aws_subnet" "rds_private_subnet_1c" { # us-west-1c
  vpc_id            = aws_vpc.vpc_production.id
  availability_zone = var.availability_zones[1]
  cidr_block        = var.subnet_cidr_blocks[5]

  tags = {
    Name = "${var.project_name}-rds-priv-1c"
  }
}

# IGW for public subnet will be attached to an ALB
resource "aws_internet_gateway" "igw_production" {
  vpc_id = aws_vpc.vpc_production.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route Table and set as main route table
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc_production.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_production.id
  }

  tags = {
    Name = "${var.project_name}-pub-rtb"
  }
}
resource "aws_main_route_table_association" "vpc_main_route" {
  vpc_id         = aws_vpc.vpc_production.id
  route_table_id = aws_route_table.public_route.id

}

# Create a NAT Gateway
resource "aws_eip" "eip_production" {
  tags = {
    Name = "${var.project_name}-eip"
  }
}
resource "aws_nat_gateway" "ngw_production" {
  allocation_id = aws_eip.eip_production.id
  subnet_id     = aws_subnet.web_public_subnet_1a.id
  tags = {
    Name = "${var.project_name}-ngw"
  }
}

# Create Private Route Table and input routing to NGW
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.vpc_production.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw_production.id
  }

  tags = {
    Name = "${var.project_name}-priv-rtb"
  }
}
resource "aws_route_table_association" "private_route_a" {
  subnet_id      = aws_subnet.app_private_subnet_1a.id
  route_table_id = aws_route_table.private_route.id
}
resource "aws_route_table_association" "private_route_b" {
  subnet_id      = aws_subnet.app_private_subnet_1c.id
  route_table_id = aws_route_table.private_route.id
}
resource "aws_route_table_association" "private_route_c" {
  subnet_id      = aws_subnet.rds_private_subnet_1a.id
  route_table_id = aws_route_table.private_route.id
}
resource "aws_route_table_association" "private_route_d" {
  subnet_id      = aws_subnet.rds_private_subnet_1c.id
  route_table_id = aws_route_table.private_route.id
}

#=====================Tier 1: Web tier (Frontend)======================#
resource "aws_key_pair" "servers_key" {
  key_name   = var.key_name
  public_key = file("${path.module}/project.pem.pub")
  tags = {
    Name = "${var.project_name}-webserver-keypair"
  }
}

resource "aws_instance" "bastion_host" {
  ami                    = "ami-0f66240e199159416"
  key_name               = aws_key_pair.servers_key.key_name
  subnet_id              = aws_subnet.web_public_subnet_1a.id
  vpc_security_group_ids = [aws_security_group.appserver_sg.id]
  instance_type          = "t2.micro"
  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }
  tags = {
    Name = "${var.project_name}-bastion-host"
  }
}

resource "aws_launch_template" "webserver_template" {
  name                   = "webserver_template"
  description            = "Production Web Server"
  image_id               = "ami-0f66240e199159416" # Amazon Linux 2
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.servers_key.key_name
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 15
      volume_type = "gp3"
    }
  }

  user_data = filebase64("${path.module}/webapp.sh")

  tags = {
    Name  = "${var.project_name}-webserver-instance"
    Shift = "ANZ-Shift"
  }

}
resource "aws_security_group" "bastion_host" {
  name        = "${var.project_name}-bastion-host"
  description = "Bastion Host security group"
  vpc_id      = aws_vpc.vpc_production.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<your-ip>"]
  }
  egress {
    description = "Connect outside"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
    Shift = "ANZ-Shift"
  }
}

resource "aws_security_group" "webserver_sg" {
  name        = "${var.project_name}-webserver-sg"
  description = "Allow SSH, HTTP, and HTTPS"
  vpc_id      = aws_vpc.vpc_production.id

  ingress {
    description = "SSH from my vpc cidr block"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_production.cidr_block]
  }
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_production.cidr_block] # will change to 0.0.0.0/0
  }
  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc_production.cidr_block] # will change to 0.0.0.0/0
  }
  egress {
    description = "Connect outside"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-webserver-sg"
  }

}

# Auto Scaling Group
resource "aws_autoscaling_group" "webserver_asg" {
  name_prefix         = "web"
  vpc_zone_identifier = [aws_subnet.web_public_subnet_1a.id, aws_subnet.web_public_subnet_1c.id]
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  target_group_arns   = [aws_lb_target_group.alb_tg_webserver.arn]

  launch_template {
    id      = aws_launch_template.webserver_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-webserver"
    propagate_at_launch = true
  }
  tag {
    key                 = "Shift"
    value               = "ANZ-Shift"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_policy" "prod_asg_policy_webserver" {
  autoscaling_group_name = aws_autoscaling_group.webserver_asg.name
  name                   = "cpu-util-policy"
  policy_type            = "TargetTrackingScaling"
  scaling_adjustment     = null
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}

# ALB
resource "aws_lb" "prod_alb_webserver" {
  name               = "prod-lb-webserver"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.webserver_sg.id}"]
  subnets            = [aws_subnet.web_public_subnet_1a.id, aws_subnet.web_public_subnet_1c.id]

  tags = {
    Name = "${var.project_name}-alb-webserver"
  }
}
resource "aws_lb_target_group" "alb_tg_webserver" {
  name     = "test-lb-webserver-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_production.id

}
resource "aws_lb_listener" "alb_listener_webserver" {
  load_balancer_arn = aws_lb.prod_alb_webserver.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_webserver.arn
  }
}



#=====================Tier 2: App tier (Backend)======================#
resource "aws_launch_template" "appserver_template" {
  name                   = "appserver_template"
  description            = "Production App Server"
  image_id               = "ami-0f66240e199159416" # Amazon Linux 2
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.servers_key.key_name
  vpc_security_group_ids = [aws_security_group.appserver_sg.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 15
      volume_type = "gp3"
    }
  }

  user_data = base64encode("${path.module}/appserver.sh")

  tags = {
    Name  = "${var.project_name}-appserver-instance"
    Shift = "ANZ-Shift"
  }
}
resource "aws_security_group" "appserver_sg" {
  name        = "${var.project_name}-appserver-sg"
  description = "Private Instances"
  vpc_id      = aws_vpc.vpc_production.id

  ingress {
    description = "SSH from public subnet 1a (bastion host)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.web_public_subnet_1a.cidr_block, aws_subnet.web_public_subnet_1c.cidr_block]
  }
  ingress {
    description = "Allow ICMPv4"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_subnet.web_public_subnet_1a.cidr_block, aws_subnet.web_public_subnet_1c.cidr_block] # will change to 0.0.0.0/0
  }
  egress {
    description = "Connect outside"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-appserver-sg"
  }
}
# Auto Scaling Group App Server
resource "aws_autoscaling_group" "appserver_asg" {
  name_prefix         = "app"
  vpc_zone_identifier = [aws_subnet.app_private_subnet_1a.id, aws_subnet.app_private_subnet_1c.id]
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  target_group_arns   = [aws_lb_target_group.alb_tg_appserver.arn]

  launch_template {
    id      = aws_launch_template.appserver_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-appserver-backend"
    propagate_at_launch = true
  }
  tag {
    key                 = "Shift"
    value               = "ANZ-Shift"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_policy" "prod_asg_policy_appserver" {
  autoscaling_group_name = aws_autoscaling_group.appserver_asg.name
  name                   = "cpu-util-policy"
  policy_type            = "TargetTrackingScaling"
  scaling_adjustment     = null
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}

# ALB
resource "aws_lb" "prod_alb_appserver" {
  name               = "prod-lb-appserver"
  internal           = true
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.appserver_sg.id}"]
  subnets            = [aws_subnet.app_private_subnet_1a.id, aws_subnet.app_private_subnet_1c.id]


  tags = {
    Name = "${var.project_name}-alb-appserver"
  }
}
resource "aws_lb_target_group" "alb_tg_appserver" {
  name     = "test-lb-appserver-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_production.id

}
resource "aws_lb_listener" "alb_listener_appserver" {
  load_balancer_arn = aws_lb.prod_alb_appserver.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_appserver.arn
  }
}

#=========Tier 3: Database tier (Data storage & retrieval)=============#
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "RDS Instances"
  vpc_id      = aws_vpc.vpc_production.id

  ingress {
    description = "Access to DB"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp" 
    security_groups = [aws_security_group.appserver_sg.id, aws_security_group.bastion_host.id] #bastion for testing if can access db
  }
  egress {
    description = "Connect outside"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-dbserver-sg"
  }
}
resource "aws_db_subnet_group" "prod_db_subgroup" {
  name       = "${var.project_name}-db-subnetgroup"
  subnet_ids = [aws_subnet.rds_private_subnet_1a.id, aws_subnet.web_public_subnet_1c.id]

  tags = {
    Name = "${var.project_name}-db-subgroup"
  }
}

# Create an RDS database
resource "aws_db_instance" "db_instance" {
  identifier     = "${var.project_name}-db"
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.micro"

  db_name  = "mydb"
  username = "admin"
  password = "mysqlpasswd" # Can use the manage_masxter_user_password via Secrets Manager

  allocated_storage = 20
  storage_type      = "gp3"

  db_subnet_group_name   = aws_db_subnet_group.prod_db_subgroup.name
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  availability_zone      = var.availability_zones[0]
  skip_final_snapshot = true


  tags = {
    Name = "${var.project_name}-rds-instance"
  }
}

#======================================================================#
#================================OUTPUTS===============================#
#======================================================================#
# Web Server
output "alb_dns_webserver" {
  value = aws_lb.prod_alb_webserver.dns_name
}
output "alb_dns_appserver" {
  value = aws_lb.prod_alb_appserver.dns_name
}
output "rds_endpoint" {
  value = aws_db_instance.db_instance.endpoint #do command: mysql -h YOUR_DB_ENDPOINT -P 3306 -u YOUR_DB_USERNAME -p
}