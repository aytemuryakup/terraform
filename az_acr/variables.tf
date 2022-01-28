variable "resource_group_name" {
  default     = "myRegistryRG"
  description = "The name for the resource group where the Azure Container Registry will reside."
}

variable "location" {
  default     = "north europe"
  description = "The location for the resource group where the Azure Container Registry will reside."
}

variable "name" {
  default     = "myRegistry"
  description = "The name for the Azure Container Registry"
}

variable "sku" {
  default     = "premium"
  description = "The SKU for the Azure Container Registry"
}

variable "enable_admin" {
  default     = false
  description = "Enable admin for the Azure Container Registry"
}

variable "georeplication_locations" {
  default     = []
  description = "Georeplication regions for the Azure Container Registry"
}

variable "webhooks" {
  description = "(Required) A list of objects describing the webhooks resources required."
  type = list(object({
    name           = string
    service_uri    = string
    status         = string
    scope          = string
    actions        = list(string)
    custom_headers = map(string)
  }))
  default = []
}

variable "tags" {}