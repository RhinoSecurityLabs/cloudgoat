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
  type        = list(string)
}

variable "ssh_public_key" {
  description = "Path to the public EC2 key"
  default     = "../cloudgoat.pub"
  type        = string
}

variable "ssh_private_key" {
  description = "Path to the private EC2 key"
  default     = "../cloudgoat"
  type        = string
}

variable "stack-name" {
  description = "Name of the stack"
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario"
  default     = "iam_privesc_by_key_rotation"
  type        = string
}
