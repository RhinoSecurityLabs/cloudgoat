terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.4.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}