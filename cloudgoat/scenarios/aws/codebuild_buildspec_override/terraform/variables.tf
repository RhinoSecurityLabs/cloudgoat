variable "cgid" {
  description = "CloudGoat scenario instance ID — appended to all resource names for uniqueness."
  type        = string
}

variable "cg_whitelist" {
  description = "List of CIDR ranges whitelisted for access to any publicly-reachable resources."
  type        = list(string)
}

variable "profile" {
  description = "AWS CLI profile that Terraform will use to deploy this scenario."
  type        = string
  default     = "cloudgoat"
}

variable "region" {
  description = "AWS region to deploy this scenario into."
  type        = string
  default     = "us-east-1"
}
