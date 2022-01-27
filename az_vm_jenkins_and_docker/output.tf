output "vm_id" {
  value = azurerm_linux_virtual_machine.linux-vm.id
}

output "vm_ip" {
  value = azurerm_linux_virtual_machine.linux-vm.public_ip_address
}

output "domain_name_label" {
  value = azurerm_public_ip.public_ip.domain_name_label
}