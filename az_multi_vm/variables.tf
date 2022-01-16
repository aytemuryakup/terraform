variable "location" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "address_space" {
  default = ["10.2.0.0/16"]
}

variable "address_prefix" {
  default = ["10.2.1.0/24"]
}

variable "environment" {
  type = string
}

variable "node_count" {
  type = number
}

variable "username" {
  description = "Enter admin username to SSH into Linux VMs"
}

variable "vm_size" {
  default = "Standard_B2s"
}

variable "vmOSpublisher" {
  default = "Canonical"
}

variable "vmOSoffer" {
  default = "UbuntuServer"
}

variable "vmOSsku" {
  default = "18.04-LTS"
}

variable "vmOSversion" {
  default = "latest"
}