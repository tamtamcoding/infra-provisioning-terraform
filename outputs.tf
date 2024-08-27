output "jenkins_server_public_ip" {
  description = "Public IP address of the Jenkins Server"
  value       = aws_instance.jenkins_server[0].public_ip
}

output "ansible_server_public_ip" {
  description = "Public IP address of the Ansible Server"
  value       = aws_instance.ansible_server[0].public_ip
}

output "webapp_server_public_ip" {
  description = "Public IP address of the Webapp Server"
  value       = aws_instance.webapp_server[0].public_ip
}

output "jenkins_server_id" {
  description = "Instance ID of the Jenkins Server"
  value       = aws_instance.jenkins_server[0].id
}

output "ansible_server_id" {
  description = "Instance ID of the Ansible Server"
  value       = aws_instance.ansible_server[0].id
}

output "webapp_server_id" {
  description = "Instance ID of the Webapp Server"
  value       = aws_instance.webapp_server[0].id
}

output "jenkins_server_private_ip" {
  description = "Private IP address of the Jenkins Server"
  value       = aws_instance.jenkins_server[0].private_ip
}

output "ansible_server_private_ip" {
  description = "Private IP address of the Ansible Server"
  value       = aws_instance.ansible_server[0].private_ip
}

output "webapp_server_private_ip" {
  description = "Private IP address of the Webapp Server"
  value       = aws_instance.webapp_server[0].private_ip
}

output "security_group_id" {
  description = "ID of the security group used by the instances"
  value       = aws_security_group.allow_all.id
}

output "cloudwatch_log_group_names" {
  description = "Names of the CloudWatch Log Groups created"
  value = [
    aws_cloudwatch_log_group.jenkins_log_group.name,
    aws_cloudwatch_log_group.ansible_log_group.name,
    aws_cloudwatch_log_group.webapp_log_group.name
  ]
}
