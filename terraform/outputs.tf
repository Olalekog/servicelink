output "public_ips" {
  description = "Public IP address of each environment's EC2 instance"
  value       = { for env, inst in aws_instance.app : env => inst.public_ip }
}

output "app_urls" {
  description = "URL where each environment's app should be reachable"
  value       = { for env, inst in aws_instance.app : env => "http://${inst.public_ip}:${var.app_port}" }
}

output "ssh_commands" {
  description = "SSH command to connect to each environment's instance"
  value       = { for env, inst in aws_instance.app : env => "ssh -i ${var.project_name}-key.pem ec2-user@${inst.public_ip}" }
}

output "private_key_path" {
  description = "Path to the generated private key, if Terraform generated one"
  value       = var.key_pair_name == null ? local_sensitive_file.private_key[0].filename : null
}
