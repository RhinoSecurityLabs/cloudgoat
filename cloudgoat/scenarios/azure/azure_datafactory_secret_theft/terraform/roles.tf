resource "azurerm_role_assignment" "cloudgoat_adf_role" {
  scope                = azurerm_data_factory.main.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = azuread_user.cloudgoat_user.object_id
  depends_on = [azurerm_key_vault.main]
}
