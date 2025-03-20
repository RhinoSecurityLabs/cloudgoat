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

variable "ssh-public-key-for-ec2" {
  description = "SSH Public Key"
  default     = "../cloudgoat.pub"
  type        = string
}

variable "ssh-private-key-for-ec2" {
  description = "SSH Private Key"
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
  default     = "ecs_efs_attack"
  type        = string
}
