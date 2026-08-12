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

variable "image_name" {
  description = "Full GHCR image reference without tag"
  type        = string
  default     = "ghcr.io/olalekog/servicelink"
}

variable "environments" {
  description = "One EC2 instance is created per entry, each running the given image tag"
  type = map(object({
    image_tag     = string
    instance_type = string
  }))
  default = {
    dev = {
      image_tag     = "dev"
      instance_type = "t3.micro"
    }
    prod = {
      image_tag     = "latest"
      instance_type = "t3.micro"
    }
  }
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
