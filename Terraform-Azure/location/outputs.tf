output "web_server_lb_public_ip_id" {
    value = azurerm_public_ip.web_server_lb_public_ip.id
}

output "bastion_host_subnet"  {
    value = azurerm_subnet.web_server_subnet["AzureBastionSubnet"].id

}

