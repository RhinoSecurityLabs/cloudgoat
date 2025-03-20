variable "profile" {
  description = "The AWS profile to use."
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources to."
  default     = "us-east-1"
  type        = string
}

#SSH Public Key
variable "ssh-public-key-for-ec2" {
  default = "../cloudgoat.pub"
}
#SSH Private Key
variable "ssh-private-key-for-ec2" {
  default = "../cloudgoat"
}
variable "cgid" {
  description = "CGID variable for unique naming."
  type        = string
}

variable "cg_whitelist" {
  description = "User's public IP address"
  type        = list(any)
}

variable "rds-username" {
  description = "RDS Mysql instance username"
  default     = "cgadmin"
  type        = string
}

variable "rds-password" {
  description = "RDS Mysql instance password"
  default     = "cgoat9562!"
  type        = string
}

variable "stack-name" {
  description = "Name of the stack."
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario."
  default     = "rds_snapshot"
  type        = string
}
