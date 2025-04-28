terraform {
  required_version = ">= 1.5"

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
