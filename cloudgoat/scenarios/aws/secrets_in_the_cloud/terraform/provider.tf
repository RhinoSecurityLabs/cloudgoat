terraform {
  required_version = ">= 1.5"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.7.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.74.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
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

provider "tls" {}
