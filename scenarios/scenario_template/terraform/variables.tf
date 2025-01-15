variable "profile" {
  description = "The AWS profile to use when deploying resources"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources into"
  default     = "us-east-1"
  type        = string
}

variable "cgid" {
  description = "CGID variable for unique naming between scenarios"
  type        = string
}

# This resources is not needed for scenarios, but should be used on any public facing resources
variable "cg_whitelist" {
  description = "User's public IP address(es)"
  type        = list(string)
}

variable "stack-name" {
  description = "Name of the stack"
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario being deployed"
  default     = "scenario_template"
  type        = string
}
