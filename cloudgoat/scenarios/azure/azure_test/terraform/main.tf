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
      prevent_deletion_if_contains_resources = false
    }
  }
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
    
