## This is used for the CloudGoat scenario to pull the AWS profile from the CloudGoat configuration. 
provider "aws" {
  profile = var.profile
  region  = var.region
}
