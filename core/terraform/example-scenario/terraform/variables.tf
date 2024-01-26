#Required
variable "profile" {
  description = "The AWS profile to use"
  type        = string
}

#Required
variable "region" {
  default = "us-east-1"
  type    = string
}

#Required
variable "cgid" {
  description = "CGID variable for unique naming"
  type        = string
}

#Required
variable "cg_whitelist" {
  description = "User's public IP address(es)"
  type        = list(string)
}

#Example
variable "rds_username" {
  description = "RDS PostgreSQL Instance Username"
  default     = "cgadmin"
  type        = string
}

#Example
variable "rds_password" {
  description = "RDS PostgreSQL Instance Password"
  default     = "Purplepwny2029"
  type        = string
}

#Example
variable "ssh_public_key" {
  description = "SSH Public Key"
  default     = "../cloudgoat.pub"
  type        = string
}

#Example
variable "ssh_private_key" {
  description = "SSH Private Key"
  default     = "../cloudgoat"
  type        = string
}
