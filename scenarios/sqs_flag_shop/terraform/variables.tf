variable "profile" {
  description = "The AWS profile to use."
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources to."
  default     = "us-east-1"
  type        = string
}

variable "cgid" {
  description = "CGID variable for unique naming."
  type        = string
}

variable "cg_whitelist" {
  description = "User's public IP address(es)"
  default     = ["0.0.0.0/0"]
  type        = list(string)
}

variable "stack-name" {
  description = "Name of the stack."
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario."
  default     = "sqs_flag_shop"
  type        = string
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

variable "rds-database-name" {
  description = "db_name"
  default     = "cash"
  type        = string
}

variable "rds_username" {
  description = "rds_db_username"
  default     = "admin"
  type        = string
}

variable "rds_password" {
  description = "rds_db_passwrod"
  default     = "bob12cgv"
  type        = string
}

variable "sqs_auth" {
  description = "sqs_auth"
  default     = "sqs_flag_shop_charging_request_auth"
  type        = string
}