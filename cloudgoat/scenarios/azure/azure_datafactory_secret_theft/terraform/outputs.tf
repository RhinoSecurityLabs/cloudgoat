output "cloudgoat_username" {
  value = azuread_user.cloudgoat_user.user_principal_name
}

output "cloudgoat_password" {
  value     = random_password.cloudgoat_password.result
  sensitive = true
}

output "data_factory_url" {
  value = "https://adf.azure.com/en/home?factory=%2Fsubscriptions%2F${var.subscription_id}%2FresourceGroups%2F${azurerm_resource_group.main.name}%2Fproviders%2FMicrosoft.DataFactory%2Ffactories%2F${azurerm_data_factory.main.name}"
}
