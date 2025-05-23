variable "subscription_id" {
  description = "The Azure Subscription ID to use when deploying resources"
  type        = string
}

variable "cgid" {
  description = "CGID variable for unique naming between scenarios"
  type        = string
}

# This resources is not needed for scenarios, but should be used on any public facing resources
variable "cg_whitelist" {
  description = "User's public IP address(es)"
  type        = list(string)
}

variable "resource_group" {
  default = "poc_resource_group"
}

variable "location" {
  type    = string
  default = "westus"
}
