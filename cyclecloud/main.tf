terraform {
  required_version = ">= 1.1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.41.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

#
# Account
#
data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

#
# RG
#
resource "azurerm_resource_group" "rg" {
  name     = var.cyclecloud_resource_group
  location = var.cyclecloud_location
}

#
# Network
#
resource "azurerm_virtual_network" "vnet" {
  name                = var.cyclecloud_vnet
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.cyclecloud_vnet_address_space]
}

resource "azurerm_subnet" "subnet" {
  name                 = var.cyclecloud_subnet
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.cyclecloud_subnet_address_prefix]
  service_endpoints    = ["Microsoft.Storage"]
}

#
# Storage - Must not be hierarchical namespace enabled to work with CycleCloud
#
resource "azurerm_storage_account" "storage" {
  name                     = var.cyclecloud_storage_account
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  is_hns_enabled           = "false"
  network_rules {
    default_action = "Deny"
    ip_rules       = [var.local_ip_address]
    virtual_network_subnet_ids = [
      azurerm_subnet.subnet.id
    ]
  }
}

resource "azurerm_storage_container" "container" {
  name                  = var.cyclecloud_storage_container
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

data "azurerm_storage_account_sas" "cyclecloud" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = true
    container = true
    object    = false
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = "2023-01-01"
  expiry = "2024-01-01"

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

#
# SSH public key
#
resource "azurerm_ssh_public_key" "public_key" {
  name                = "public-key"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  public_key          = file(var.public_key_path)
}

#
# User identify for CycleCloud nodes
#
resource "azurerm_user_assigned_identity" "cyclecloud_node" {
  name                = "cyclecloud-node"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "cyclecloud_node" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"

  principal_id = azurerm_user_assigned_identity.cyclecloud_node.principal_id
}
