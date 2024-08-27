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
  ami           = "ami-0c55b159cbfafe1f0"  # Specify the appropriate AMI for Jenkins server
  instance_type = "t2.micro"
  security_groups = [aws_security_group.allow_all.name]

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  tags = {
    Name = "Jenkins-Server"
  }
}

resource "aws_instance" "ansible_server" {
  count         = 1
  ami           = "ami-0c55b159cbfafe1f0"  # Specify the appropriate AMI for Ansible server
  instance_type = "t2.micro"
  security_groups = [aws_security_group.allow_all.name]

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  tags = {
    Name = "Ansible-Server"
  }
}

resource "aws_instance" "webapp_server" {
  count         = 1
  ami           = "ami-0c55b159cbfafe1f0"  # Specify the appropriate AMI for Webapp server
  instance_type = "t2.medium"
  security_groups = [aws_security_group.allow_all.name]

  root_block_device {
    volume_size = 25
    volume_type = "gp2"
  }

  tags = {
    Name = "Webapp-Server"
  }
}


resource "aws_instance" "example" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name = var.name
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF

  lifecycle {
    create_before_destroy = true
  }
}