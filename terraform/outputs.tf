output "public_ip" {
  description = "Public IP address of this workspace's EC2 instance (null in the default workspace)"
  value       = length(aws_instance.app) > 0 ? aws_instance.app[0].public_ip : null
}

output "app_url" {
  description = "URL where this workspace's app should be reachable"
  value       = length(aws_instance.app) > 0 ? "http://${aws_instance.app[0].public_ip}:${var.app_port}" : null
}

output "instance_id" {
  description = "ID of this workspace's EC2 instance (used as the SSM deploy target)"
  value       = length(aws_instance.app) > 0 ? aws_instance.app[0].id : null
}

output "ssm_session_command" {
  description = "Command to open an interactive shell on this workspace's instance via SSM"
  value       = length(aws_instance.app) > 0 ? "aws ssm start-session --target ${aws_instance.app[0].id} --region ${var.aws_region}" : null
}

output "security_group_id" {
  description = "ID of the shared security group (set this as security_group_id in dev.tfvars/prod.tfvars)"
  value       = local.security_group_id
}

output "key_name" {
  description = "Name of the shared SSH key pair (set this as key_pair_name in dev.tfvars/prod.tfvars)"
  value       = local.key_name
}

output "instance_profile_name" {
  description = "Name of the shared IAM instance profile (set this as instance_profile_name in dev.tfvars/prod.tfvars)"
  value       = local.instance_profile_name
}

output "private_key_path" {
  description = "Path to the generated private key, if Terraform generated one (default workspace only)"
  value       = var.key_pair_name == null ? try(local_sensitive_file.private_key[0].filename, null) : null
}
