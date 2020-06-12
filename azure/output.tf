output "instance_ip_addr" {
    value = azurerm_linux_virtual_machine.terraform.public_ip_address
}