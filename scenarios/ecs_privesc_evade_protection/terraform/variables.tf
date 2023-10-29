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
  description = "User's public IP address(es)."
  type        = list(string)
  default     = ["127.0.0.1/24"]
}

variable "stack-name" {
  description = "Name of the stack."
  default     = "CloudGoat"
  type        = string
}

variable "scenario-name" {
  description = "Name of the scenario."
  default     = "ecs_task_shell"
  type        = string
}

variable "user_email" {
  description = "Once guardduty detects attack, a mail will be sent to you"
  type        = string
}

