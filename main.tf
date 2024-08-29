# terraform {
#   backend "s3" {
#     bucket         = "tamtamcoding110824"
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-lock"  # DynamoDB table for state locking
#   }
# }

provider "aws" {
  region = var.aws_region
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Subnet Configuration
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "main-subnet"
  }
}

# Security Group Configuration
resource "aws_security_group" "allow_ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_ssh_traffic"
  description = "Allow SSH traffic only"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP range for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh"
  }
}

# AMI Data Source
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Instance Configuration Template
resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.main.id

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install java-1.8.0-openjdk jenkins amazon-cloudwatch-agent
              sudo systemctl start jenkins
              sudo systemctl enable jenkins
              EOF

  provisioner "local-exec" {
    command = "sleep 30" # Wait for the instance to initialize
  }

  provisioner "file" {
    source      = "aws_cloudwatch_agent/jenkins_cloudwatch_agent.json"
    destination = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("private_key.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart amazon-cloudwatch-agent",
    ]
  }

  tags = {
    Name = "Jenkins-Server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Repeat similar configurations for ansible_server and webapp_server

# Ansible Server Instance
resource "aws_instance" "ansible_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.main.id

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install ansible
              sudo yum -y install amazon-cloudwatch-agent
              sudo yum -y install git
              EOF
  
  provisioner "local-exec" {
  command = "sleep 30" # Wait for the instance to initialize
  }

  provisioner "file" {
    source      = "aws_cloudwatch_agent/ansible_cloudwatch_agent.json"
    destination = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("private_key.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart amazon-cloudwatch-agent",
    ]
  }

  tags = {
    Name = "Ansible-Server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Webapp Server Instance
resource "aws_instance" "webapp_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.main.id

  root_block_device {
    volume_size = 25
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install httpd
              sudo yum -y install amazon-cloudwatch-agent
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF
              
    provisioner "local-exec" {
      command = "sleep 30" # Wait for the instance to initialize
    }

  provisioner "file" {
    source      = "aws_cloudwatch_agent/webapp_cloudwatch_agent.json"
    destination = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("private_key.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart amazon-cloudwatch-agent",
    ]
  }

  tags = {
    Name = "Webapp-Server"
  }

  lifecycle {
    create_before_destroy = true
  }
}
