locals {
  web_server_name   = var.environment == "production" ? "${var.web_server_name}-prd" : "${var.web_server_name}-dev"
  build_environment = var.environment == "production" ? "production" : "development"
}

resource "azurerm_resource_group" "web_server_rg" {
  name     = var.web_server_rg
  location = var.web_server_location

  tags = {
    environment   = local.build_environment
    build-version = var.terraform_script_version
  }
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  address_space       = [var.web_server_address_space]
}

resource "azurerm_subnet" "web_server_subnet" {
  for_each = var.web_server_subnets

    name                 = each.key
    resource_group_name  = azurerm_resource_group.web_server_rg.name
    virtual_network_name = azurerm_virtual_network.web_server_vnet.name
    address_prefix       = each.value
}

resource "azurerm_public_ip" "web_server_lb_public_ip" {
  name                = "${var.resource_prefix}-public-ip"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  allocation_method   = var.environment == "production" ? "Static" : "Dynamic"
  domain_name_label   = var.domain_name_label # TRAFFIC MANAGER
}



resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.resource_prefix}-nsg"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
  count = var.environment     == "production" ? 0 : 1
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_http" {
  name                        = "HTTP Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "web_server_sag" {
  network_security_group_id = azurerm_network_security_group.web_server_nsg.id
  subnet_id                 = azurerm_subnet.web_server_subnet["web-server"].id
}

resource "random_string" "random" {
  length  = 10
  upper   = false
  special = false
  number  = false
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "bootdiags${random_string.random.result}"
  location                 = var.web_server_location
  resource_group_name      = azurerm_resource_group.web_server_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_machine_scale_set" "web_server" {
  name                = "${var.resource_prefix}-scale-set"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  upgrade_policy_mode = "manual"

  sku {
    name     = "Standard_B1s"
    tier     = "Standard"
    capacity = var.web_server_count
  }

  storage_profile_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1709-smalldisk"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = local.web_server_name
    admin_username       = "webserver"
    admin_password       = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  network_profile {
    name    = "web_server_network_profile"
    primary = true

    ip_configuration {
      name                                   = local.web_server_name
      primary                                = true
      subnet_id                              = azurerm_subnet.web_server_subnet["web-server"].id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id]      
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
  }

  extension {
    name                 = "${local.web_server_name}-extension"
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"

    settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/eltimmo/learning/master/azureInstallWebServer.ps1"],
      "commandToExecute": "start powershell -ExecutionPolicy Unrestricted -File azureInstallWebServer.ps1"
    }
    SETTINGS

  }
}

resource "azurerm_lb" "web_server_lb" {
  name                = "${var.resource_prefix}-lb"
  resource_group_name = azurerm_resource_group.web_server_rg.name  
  location            = var.web_server_location


  frontend_ip_configuration {
    name                 = "${var.resource_prefix}-lb-frontend-ip"
    public_ip_address_id = azurerm_public_ip.web_server_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_server_lb_backend_pool" {
  name                = "${var.resource_prefix}-lb-backend-pool"
  resource_group_name = azurerm_resource_group.web_server_rg.name
  loadbalancer_id     = azurerm_lb.web_server_lb.id
}

resource "azurerm_lb_probe" "web_server_lb_http_probe" {
  name                = "${var.resource_prefix}-lb-http-probe"
  resource_group_name = azurerm_resource_group.web_server_rg.name
  loadbalancer_id     = azurerm_lb.web_server_lb.id
  protocol            = "tcp"
  port                = "80"
}

resource "azurerm_lb_rule" "web_server_lb_http_rule" {
  name                           = "${var.resource_prefix}-lb-http-rule"
  resource_group_name            = azurerm_resource_group.web_server_rg.name
  loadbalancer_id                = azurerm_lb.web_server_lb.id
  protocol                       = "tcp"
  frontend_port                  = "80"
  backend_port                   = "80"
  frontend_ip_configuration_name = "${var.resource_prefix}-lb-frontend-ip"
  probe_id                       = azurerm_lb_probe.web_server_lb_http_probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id
}