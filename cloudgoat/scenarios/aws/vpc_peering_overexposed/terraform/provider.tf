## AWS Provider Configuration for vpc_peering_overexposed scenario
## Configure required Terraform and provider versions.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.74.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region

  # This configures default tags for all resources
  default_tags {
    tags = {
      Name     = "vpc-peering-${var.cgid}"
      Stack    = var.stack-name
      Scenario = var.scenario-name
    }
  }
} 