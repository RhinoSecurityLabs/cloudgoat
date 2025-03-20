terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0" # 4.x requires subscription ID. Sticking with this version until it's possible to pull subID somehow
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false #Nuke the resource group and everything in it if nested resources fail to destroy
    }
  }
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "The Azure Subscription ID to use when deploying resources"
  type = string
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

resource "azurerm_resource_group" "poc" {
  name     = var.resource_group
  location = var.location
}
  
output "Success"{
  value = "Resource group ${var.resource_group} created. POC worked!"
}
    
