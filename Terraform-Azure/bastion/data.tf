data "terraform_remote_state" "web" {
	backend = "azurerm" 
    config = {
		resource_group_name = "state"
		storage_account_name = "tfstateaur"
		container_name       = "tfstate"
		key                  = "web.tfstate"
     }
}



# THIS WILL CAPTURE THE DATA FROM THE INFRA REMOTE STATE web.tfstate










