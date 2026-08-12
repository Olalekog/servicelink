output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "URL where the app should be reachable"
  value       = "http://${aws_instance.app.public_ip}:${var.app_port}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.project_name}-key.pem ec2-user@${aws_instance.app.public_ip}"
}

output "private_key_path" {
  description = "Path to the generated private key, if Terraform generated one"
  value       = var.key_pair_name == null ? local_sensitive_file.private_key[0].filename : null
}
