provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "bastion_rg" {
  name = var.bastion_rg
  location = var.location 

} 

resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.bastion_rg.name
  allocation_method   = "Static" # TRAFFIC MANAGER
  sku = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {      #YOU CAN HAVE ONE BASTION PER SUBNET
    name = "bastion_host"
    resource_group_name = azurerm_resource_group.bastion_rg.name 
    location = var.location 

    ip_configuration {
        name = "us2w"
        subnet_id = data.terraform_remote_state.web.outputs.bastion_host_subnet_us2w
        public_ip_address_id = azurerm_public_ip.bastion_pip.id
    }
}

