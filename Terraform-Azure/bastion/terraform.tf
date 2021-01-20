terraform {
  backend "azurerm" {
    resource_group_name  = "state"
    storage_account_name = "tfstateaur"
    container_name       = "tfstate"
    key                  = "bastion.tfstate"
  }
}

