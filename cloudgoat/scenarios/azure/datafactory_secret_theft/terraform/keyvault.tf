resource "azurerm_key_vault" "main" {
  name                = "cgkv${var.cgid}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku_name            = "standard"
  tenant_id           = data.azuread_client_config.current.tenant_id
}

resource "azurerm_key_vault_access_policy" "main" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = data.azuread_client_config.current.object_id
  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

resource "azurerm_key_vault_secret" "storage_key" {
  name         = "cg-flag-${var.cgid}"
  value        = "cg-flag-33bf9df3-ccad-4887-be22-9c36f26bb32d"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.main, azurerm_key_vault.main]
}

resource "azurerm_key_vault_access_policy" "datafactory" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = data.azurerm_data_factory.main.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [azurerm_data_factory.main]
}
