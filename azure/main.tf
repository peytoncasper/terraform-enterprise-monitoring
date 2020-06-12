provider "azurerm" {
    features{}
}

resource "random_integer" "log_analytics_modifier" {
  min     = 100
  max     = 200
}

resource "azurerm_resource_group" "terraform" {
  name     = "terraform-resources"
  location = "East US"
}

resource "azurerm_network_security_group" "terraform" {
  name                = "terraform-security-group"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  security_rule {
    name                       = "terraform-admin-ui"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8800"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "terraform-http"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "terraform-https"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "terraform" {
  name                = "terraform-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
}

resource "azurerm_subnet" "terraform" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.terraform.name
  virtual_network_name = azurerm_virtual_network.terraform.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "terraform" {
  name                = "terraform-public-ip"
  resource_group_name = azurerm_resource_group.terraform.name
  location            = azurerm_resource_group.terraform.location
  allocation_method   = "Static"
}


resource "azurerm_network_interface" "terraform" {
  name                = "terraform-nic"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terraform.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform.id
  }
}

resource "azurerm_storage_account" "terraform" {
  name                     = "terraformstorageacc132"
  resource_group_name      = azurerm_resource_group.terraform.name
  location                 = azurerm_resource_group.terraform.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "terraform" {
  name                  = "terraform-container"
  storage_account_name  = azurerm_storage_account.terraform.name
  container_access_type = "private"
}


resource "azurerm_postgresql_server" "terraform" {
  name                = "terraform-postgresql-server"
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name

  sku_name = "B_Gen5_1"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false

  administrator_login          = var.pg_admin_username
  administrator_login_password = var.pg_admin_password
  version                      = "9.5"
  ssl_enforcement_enabled      = false
}

resource "azurerm_postgresql_firewall_rule" "terraform" {
  name                = "AllowAllAzureIps"
  resource_group_name = azurerm_resource_group.terraform.name
  server_name         = azurerm_postgresql_server.terraform.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_database" "terraform" {
  name                = "terraformdb"
  resource_group_name = azurerm_resource_group.terraform.name
  server_name         = azurerm_postgresql_server.terraform.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}



resource "azurerm_log_analytics_workspace" "terraform" {
  name                = join("", ["terraform-workspace",random_integer.log_analytics_modifier.result])
  location            = azurerm_resource_group.terraform.location
  resource_group_name = azurerm_resource_group.terraform.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "terraform" {
  solution_name         = "Containers"
  location              = azurerm_resource_group.terraform.location
  resource_group_name   = azurerm_resource_group.terraform.name
  workspace_resource_id = azurerm_log_analytics_workspace.terraform.id
  workspace_name        = azurerm_log_analytics_workspace.terraform.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Containers"
  }
}

resource "azurerm_linux_virtual_machine" "terraform" {
  name                = "terraform-machine"
  resource_group_name = azurerm_resource_group.terraform.name
  location            = azurerm_resource_group.terraform.location
  size                = "Standard_B2S"
  admin_username      = var.vm_admin_username
  network_interface_ids = [
    azurerm_network_interface.terraform.id,
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(var.public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "60"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("scripts/terraform.sh", {
    "PRIVATE_IP_ADDRESS" = azurerm_network_interface.terraform.private_ip_address,
    "PUBLIC_IP_ADDRESS"  = azurerm_public_ip.terraform.ip_address,
    "ENCRYPTION_PASSWORD"= var.encryption_password,
    "AZURE_ACCOUNT_KEY"  = azurerm_storage_account.terraform.primary_access_key,
    "AZURE_ACCOUNT_NAME" = azurerm_storage_account.terraform.name,
    "AZURE_CONTAINER"    = azurerm_storage_container.terraform.name,
    "PG_DB_NAME"         = azurerm_postgresql_database.terraform.name,
    "PG_USERNAME"        = join("@", [var.pg_admin_username,azurerm_postgresql_server.terraform.name]),
    "PG_PASSWORD"        = var.pg_admin_password,
    "PG_ENDPOINT"        = azurerm_postgresql_server.terraform.fqdn,
    "LICENSE"            = var.license
    "WORKSPACE_ID"       = azurerm_log_analytics_workspace.terraform.workspace_id
    "WORKSPACE_KEY"      = azurerm_log_analytics_workspace.terraform.primary_shared_key
  }))

  depends_on = [
    azurerm_public_ip.terraform,
    azurerm_log_analytics_workspace.terraform
  ]
}