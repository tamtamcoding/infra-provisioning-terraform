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

# Reading the JSON configuration files
data "local_file" "jenkins_cloudwatch_agent" {
  filename = "${path.module}/aws_cloudwatch_agent/jenkins_cloudwatch_agent.json"
}

data "local_file" "ansible_cloudwatch_agent" {
  filename = "${path.module}/aws_cloudwatch_agent/ansible_cloudwatch_agent.json"
}

data "local_file" "webapp_cloudwatch_agent" {
  filename = "${path.module}/aws_cloudwatch_agent/webapp_cloudwatch_agent.json"
}

resource "aws_instance" "jenkins_server" {
  count         = 1
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
              sudo systemctl start jenkins
              sudo systemctl enable jenkins

              # Create the directory for the CloudWatch Agent configuration
              sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

              # Write the CloudWatch Agent configuration file
              cat <<EOT >> /opt/aws/amazon-cloudwatch-agent/etc/jenkins_cloudwatch_agent.json
              ${data.local_file.jenkins_cloudwatch_agent.content}
              EOT

              # Install and configure CloudWatch Agent
              sudo yum install -y amazon-cloudwatch-agent
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/jenkins_cloudwatch_agent.json \
                -s
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
  key_name      = var.key_name

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install ansible
              sudo yum -y install git

              # Create the directory for the CloudWatch Agent configuration
              sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

              # Write the CloudWatch Agent configuration file
              cat <<EOT >> /opt/aws/amazon-cloudwatch-agent/etc/ansible_cloudwatch_agent.json
              ${data.local_file.ansible_cloudwatch_agent.content}
              EOT

              # Install and configure CloudWatch Agent
              sudo yum install -y amazon-cloudwatch-agent
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/ansible_cloudwatch_agent.json \
                -s
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
  key_name      = var.key_name

  root_block_device {
    volume_size = 25
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd

              # Create the directory for the CloudWatch Agent configuration
              sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

              # Write the CloudWatch Agent configuration file
              cat <<EOT >> /opt/aws/amazon-cloudwatch-agent/etc/webapp_cloudwatch_agent.json
              ${data.local_file.webapp_cloudwatch_agent.content}
              EOT

              # Install and configure CloudWatch Agent
              sudo yum install -y amazon-cloudwatch-agent
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/webapp_cloudwatch_agent.json \
                -s
              EOF

  tags = {
    Name = "Webapp-Server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "jenkins_log_group" {
  name              = "/aws/jenkins/jenkins-server"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ansible_log_group" {
  name              = "/aws/ansible/ansible-server"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "webapp_log_group" {
  name              = "/aws/webapp/webapp-server"
  retention_in_days = 14
}
