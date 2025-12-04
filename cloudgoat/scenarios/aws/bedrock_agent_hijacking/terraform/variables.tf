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
  default     = "bedrock_agent_hijacking"
  type        = string
}

# Additional scenario-specific variables
variable "agent_model_id" {
  description = "The ID of the foundational model used by the agent."
  type        = string
  default     = "amazon.nova-lite-v1:0"
}
