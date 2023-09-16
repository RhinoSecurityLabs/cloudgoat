variable "profile" {
  description = "The AWS profile to use."
}

variable "region" {
  description = "The AWS region to deploy resources to."
  default = "us-east-1"
}

variable "cgid" {
  description = "CGID variable for unique naming."
}

variable "cg_whitelist" {
  description = "User's public IP address(es)."
  type = list(string)
}

variable "stack-name" {
  description = "Name of the stack."
  default = "CloudGoat"
}

variable "scenario-name" {
  description = "Name of the scenario."
  default = "vulnerable_cognito"
}
