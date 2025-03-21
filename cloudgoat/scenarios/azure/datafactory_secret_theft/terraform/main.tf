resource "azurerm_resource_group" "main" {
  name     = "cg_rg_${var.cgid}"
  location = var.location
}

# Enable Managed Identity for Data Factory
resource "azurerm_data_factory" "main" {
  name                = "cg-datafactory-${var.cgid}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
}

# Create Data Factory Linked Service for Key Vault
resource "azurerm_data_factory_linked_service_key_vault" "main" {
  name            = "cg-adf-${var.cgid}-keyvault"
  data_factory_id = azurerm_data_factory.main.id
  key_vault_id    = azurerm_key_vault.main.id
}

# ✅ Fetch the correct Managed Identity Object ID (ONLY ONE INSTANCE)
data "azurerm_data_factory" "main" {
  name                = azurerm_data_factory.main.name
  resource_group_name = azurerm_resource_group.main.name
}

data "azuread_client_config" "current" {}
