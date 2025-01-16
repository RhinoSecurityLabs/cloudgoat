variable "profile" {
  description = "The AWS profile to use"
  type        = string
}

variable "cgid" {
  description = "CGID variable for unique naming"
  type        = string
}

variable "region" {
  default = "us-east-1"
  type    = string
}

variable "cg_whitelist" {
  description = "User's public IP address(es)"
  default     = ["0.0.0.0/0"]
  type        = list(string)
}

variable "stack-name" {
  description = "Name of the stack"
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario"
  default     = "iam-privesc-by-attachment"
  type        = string
}
