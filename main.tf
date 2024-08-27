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
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.allow_all.name]
  key_name      = var.key_name

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install java-1.8.0-openjdk
              sudo yum -y install jenkins
              sudo yum -y install amazon-cloudwatch-agent
              sudo systemctl start jenkins
              sudo systemctl enable jenkins
              EOF

  provisioner "file" {
    source      = "aws_cloudwatch_agent/jenkins_cloudwatch_agent.json"
    destination = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
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

resource "aws_instance" "ansible_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.allow_all.name]
  key_name      = var.key_name

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

  provisioner "file" {
    source      = "aws_cloudwatch_agent/ansible_cloudwatch_agent.json"
    destination = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
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

resource "aws_instance" "webapp_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.medium"
  security_groups = [aws_security_group.allow_all.name]
  key_name      = var.key_name

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

  provisioner "file" {
    source      = "aws_cloudwatch_agent/webapp_cloudwatch_agent.json"
    destination = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
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
