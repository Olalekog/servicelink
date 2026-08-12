terraform {
  required_version = ">= 1.10" # needed for S3 native state locking (use_lockfile)

  backend "s3" {
    bucket       = "servicelink-terraform-state-866934333672"
    key          = "servicelink/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
