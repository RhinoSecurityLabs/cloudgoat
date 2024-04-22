terraform {
  # Minimum Terraform version
  required_version = ">= 1.5"

  # Minimum AWS provider version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# Specify what region and credentials to use
provider "aws" {
  profile = var.profile
  region  = var.region
}
