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
  default     = "agent_tool_hijacking"
  type        = string
}

# Additional scenario-specific variables

variable "final_flag" {
  description = "The final flag stored in Secrets Manager"
  type        = string
  default     = "FLAG{ag3nt5_c@n_b3_pr1v1l3g3d_t00}"
}
