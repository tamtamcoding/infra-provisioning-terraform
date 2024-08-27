# terraform {
#   backend "s3" {
#     bucket         = "tamtamcoding110824"
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-lock"  # DynamoDB table for state locking
#   }
# }

provider "aws" {
  region = var.aws_region # Specify your preferred region
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all_traffic"
  description = "Security group to allow all incoming traffic"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_server" {
  count         = 1
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.allow_all.name]
  key_name      = var.key_name  # Add this line to specify the SSH key pair

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }
    user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install java-1.8.0-openjdk  # Example: Jenkins dependency
              sudo yum -y install jenkins  # Install Jenkins
              sudo systemctl start jenkins
              sudo systemctl enable jenkins
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
      lifecycle {
        create_before_destroy = true
    }
}

resource "aws_instance" "ansible_server" {
  count         = 1
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.allow_all.name]
  key_name      = var.key_name  # Add this line to specify the SSH key pair

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }
    user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install ansible  # Install Ansible
              sudo yum -y install git  # Install Git (if needed)
              EOF

  tags = {
    Name = "Ansible-Server"
  }
      lifecycle {
        create_before_destroy = true
    }
}

resource "aws_instance" "webapp_server" {
  count         = 1
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.medium"
  security_groups = [aws_security_group.allow_all.name]
  key_name      = var.key_name  # Add this line to specify the SSH key pair

  root_block_device {
    volume_size = 25
    volume_type = "gp2"
  }
    user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install httpd  # Install Apache HTTP server
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF

  tags = {
    Name = "Webapp-Server"
  }
    lifecycle {
        create_before_destroy = true
    }
}
