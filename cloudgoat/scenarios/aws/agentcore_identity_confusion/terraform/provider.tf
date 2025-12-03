## This is used for the CloudGoat scenario to pull the AWS profile from the CloudGoat configuration.
## Configure required Terraform and provider versions.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.74.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "= 2.2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region

  # This configures default tags for all resources
  default_tags {
    tags = {
      Name     = "cg-${var.cgid}"
      Stack    = var.stack-name
      Scenario = var.scenario-name
    }
  }
}