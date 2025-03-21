# variable "cg_whitelist" {
#   description = "User's public IP address(es)"
#   type        = list(string)
#   default     = []
# }

variable "cgid" {
  description = "CGID variable for unique naming between scenarios"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure region to deploy resources in"
  type        = string
  default     = "East US"
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
  default     = ""
}