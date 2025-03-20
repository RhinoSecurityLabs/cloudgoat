terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
	    purge_soft_delete_on_destroy = false
	  }
  }
  subscription_id = var.subscription_id
}

provider "azuread" {}
