provider "aws" {
  profile = var.profile
  region  = var.region

  default_tags {
    tags = {
      Name     = "cg-${var.cgid}"
      Stack    = var.stack-name
      Scenario = var.scenario-name
    }
  }
}