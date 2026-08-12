variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix used for tagging and resource names"
  type        = string
  default     = "servicelink"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "image_name" {
  description = "Full GHCR image reference without tag"
  type        = string
  default     = "ghcr.io/olalekog/servicelink"
}

variable "image_tag" {
  description = "Image tag to pull and run"
  type        = string
  default     = "latest"
}

variable "app_port" {
  description = "Port the Flask app listens on inside the container"
  type        = number
  default     = 8080
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name to use for SSH. Leave null to have Terraform generate one."
  type        = string
  default     = null
}
