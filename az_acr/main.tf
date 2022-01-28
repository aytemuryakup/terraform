resource "azurerm_resource_group" "group" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_container_registry" "registry" {
  count                    = var.georeplication_locations == [] ? 1 : 0

  name                     = var.name
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  sku                      = var.sku
  admin_enabled            = var.enable_admin
  tags                     = var.tags
}

resource "azurerm_container_registry" "registry_georeplicated" {
  count                    = var.georeplication_locations != [] ? 1 : 0

  name                     = var.name
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  sku                      = var.sku
  admin_enabled            = var.enable_admin
  georeplication_locations = var.georeplication_locations
  tags                     = var.tags
}

resource "azurerm_container_registry_webhook" "webhooks" {
  for_each = { for object in var.webhooks : object.name => object }

  depends_on = [azurerm_container_registry.registry]

  name                = each.value.name
  resource_group_name = azurerm_resource_group.group.name
  registry_name       = var.georeplication_locations == [] ? azurerm_container_registry.registry[0].name : azurerm_container_registry.registry_georeplicated[0].name
  location            = azurerm_resource_group.group.location

  service_uri = each.value.service_uri
  status      = each.value.status      
  scope       = each.value.scope       
  actions     = each.value.actions     
  custom_headers = each.value.custom_headers
}