resource "azurerm_resource_group" "poc" {
  name     = var.resource_group
  location = var.location
}
