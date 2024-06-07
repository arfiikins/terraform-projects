# For the Access Key, you will need to do the AWS configure since it is not best practice to hardcode the Access Keys

variable "name_identifier" {
  description = "The name identifier for the resources"
  default     = "jana"
  type        = string
}

# North California provider deploy an EC2 instance and connect to default settings. Added a Security Group to allow ingress rule: HTTPS from * and 
# egress rule: * from *

resource "aws_instance" "apache-webserver" {
  provider        = aws.ncali
  ami             = "ami-08012c0a9ee8e21c4" # Ubuntu 24.04 LTS
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.apache_key_pair.key_name
  security_groups = [aws_security_group.allow_HTTPS_access.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install apache2 -y
              echo "<h1>${var.name_identifier} Apache Server</h1>" > /var/www/html/index.html
              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF

  tags = {
    Name  = "${var.name_identifier}-apache-webserver"
    Shift = "ANZ-Shift" # Avoid termination created from a Lambda function without proper tagging
  }

}

resource "aws_security_group" "allow_HTTPS_access" {
  provider    = aws.ncali
  name        = "allow_https"
  description = "Allow only HTTPS ingress traffic from all and allow all egress traffic"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_key_pair" "apache_key_pair" {
  provider   = aws.ncali
  key_name   = "apacher-key-tf"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
  tags = {
    Name = "${var.name_identifier}-apache-webserver"
  }
}

# North Virginia provider deploy RDS database connects to default setting

resource "aws_db_instance" "db_instance" {
  provider          = aws.nvirg
  identifier        = "myuniquedbinstance"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "t2.micro"

  db_name           = "mydb"
  username          = "admin"  
  password          = "passwd" # Can use the manage_masxter_user_password via Secrets Manager

  allocated_storage = 30
  storage_type      = "gp3"

  tags = {
    Name = "${var.name_identifier}-rds-instance"
  }
}
