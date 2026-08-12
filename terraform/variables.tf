variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "project_name" {
  description = "Name prefix used for tagging and resource names"
  type        = string
}

variable "image_name" {
  description = "Full GHCR image reference without tag"
  type        = string
}

variable "app_port" {
  description = "Port the Flask app listens on inside the container"
  type        = number
}

variable "image_tag" {
  description = "Image tag to run in this environment. Only used outside the default workspace."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for this environment's instance. Only used outside the default workspace."
  type        = string
  default     = "t3.micro"
}

variable "security_group_id" {
  description = "Existing security group ID to attach the instance to. Leave null in the default workspace to create one."
  type        = string
  default     = null
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name to use for SSH. Leave null to have Terraform generate one."
  type        = string
  default     = null
}

variable "instance_profile_name" {
  description = "Existing IAM instance profile name (for SSM access). Leave null in the default workspace to create one."
  type        = string
  default     = null
}
