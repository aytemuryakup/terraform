variable "location" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "tags" {
    type = map(string)
    default = {
        Environment = "Terraform LB Lab"
        Dept = "DevOps"
        dev     = "dev"
  }
}

variable "lb_sku" {
  default = "Standard"
}

variable "address_space" {
  default = ["10.2.0.0/16"]
}

variable "address_prefix" {
  default = ["10.2.1.0/24"]
}

variable "node_count" {
  type = number
}

variable "vm_size" {
  default = "Standard_B2s"
}

variable "vmOSpublisher" {
  default = "Canonical"
}

variable "vmOSoffer" {
  default = "0001-com-ubuntu-server-focal"
}

variable "vmOSsku" {
  default = "20_04-lts-gen2"
}

variable "vmOSversion" {
  default = "latest"
}

variable "username" {
  description = "Enter admin username to SSH into Linux VMs"
}

variable "password" {
  description = "Enter admin password to SSH into Linux VMs"
}