output "container_registry_id" {
  description = "The ID for the Azure Container Registry"
  value = var.georeplication_locations == [] ? azurerm_container_registry.registry[0].id : azurerm_container_registry.registry_georeplicated[0].id
  # value = azurerm_container_registry.registry.id
}

output "container_registry_location" {
  description = "The location for the Azure Container Registry"
  value = azurerm_container_registry.registry.location
}
 
output "container_registry_name" {
  description = "The name for the Azure Container Registry"
  value = azurerm_container_registry.registry.name
}
 