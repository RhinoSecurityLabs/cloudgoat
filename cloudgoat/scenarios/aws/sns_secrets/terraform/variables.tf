variable "profile" {
  description = "The AWS profile to use"
  type        = string
}

variable "cgid" {
  description = "CGID variable for unique naming"
  type        = string
}

variable "cg_whitelist" {
  description = "User's public IP address(es)"
  type        = list(string)
}

variable "region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
  type        = string
}

variable "stack-name" {
  description = "Name of the CloudGoat stack"
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario"
  default     = "iam_privesc_by_key_rotation"
  type        = string
}