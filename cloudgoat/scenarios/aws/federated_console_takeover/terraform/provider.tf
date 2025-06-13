# AWS Provider Configuration for federated_console_takeover scenario
# Configure required Terraform and provider versions.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.74.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
  
  default_tags {
    tags = {
      Stack    = var.stack-name
      Scenario = var.scenario-name
    }
  }
} 