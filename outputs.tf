output "jenkins_server_public_ip" {
  description = "The public IP address of the Jenkins server"
  value       = aws_instance.jenkins_server.public_ip
}

output "ansible_server_public_ip" {
  description = "The public IP address of the Ansible server"
  value       = aws_instance.ansible_server.public_ip
}

output "webapp_server_public_ip" {
  description = "The public IP address of the Webapp server"
  value       = aws_instance.webapp_server.public_ip
}

output "jenkins_server_id" {
  description = "The ID of the Jenkins server"
  value       = aws_instance.jenkins_server.id
}

output "ansible_server_id" {
  description = "The ID of the Ansible server"
  value       = aws_instance.ansible_server.id
}

output "webapp_server_id" {
  description = "The ID of the Webapp server"
  value       = aws_instance.webapp_server.id
}

output "jenkins_server_private_ip" {
  description = "The private IP address of the Jenkins server"
  value       = aws_instance.jenkins_server.private_ip
}

output "ansible_server_private_ip" {
  description = "The private IP address of the Ansible server"
  value       = aws_instance.ansible_server.private_ip
}

output "webapp_server_private_ip" {
  description = "The private IP address of the Webapp server"
  value       = aws_instance.webapp_server.private_ip
}
