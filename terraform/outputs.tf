output "public_ip" {
  description = "Public IP address of this workspace's EC2 instance (null in the default workspace)"
  value       = length(aws_instance.app) > 0 ? aws_instance.app[0].public_ip : null
}

output "app_url" {
  description = "URL where this workspace's app should be reachable"
  value       = length(aws_instance.app) > 0 ? "http://${aws_instance.app[0].public_ip}:${var.app_port}" : null
}

output "ssh_command" {
  description = "SSH command to connect to this workspace's instance"
  value       = length(aws_instance.app) > 0 ? "ssh -i ${var.project_name}-key.pem ec2-user@${aws_instance.app[0].public_ip}" : null
}

output "security_group_id" {
  description = "ID of the shared security group (set this as security_group_id in dev.tfvars/prod.tfvars)"
  value       = local.security_group_id
}

output "key_name" {
  description = "Name of the shared SSH key pair (set this as key_pair_name in dev.tfvars/prod.tfvars)"
  value       = local.key_name
}

output "private_key_path" {
  description = "Path to the generated private key, if Terraform generated one (default workspace only)"
  value       = var.key_pair_name == null ? try(local_sensitive_file.private_key[0].filename, null) : null
}
