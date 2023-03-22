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

data "azurerm_virtual_network" "existing_vnet" {
  name                = var.existing_vnet
  resource_group_name = var.existing_vnet_rg
}

resource "azurerm_virtual_network_peering" "cyclecloud_to_existing" {
  name                      = "cc-to-${var.cyclecloud_vnet}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.existing_vnet.id
  use_remote_gateways       = true
}

resource "azurerm_virtual_network_peering" "existing_to_cyclecloud" {
  name                      = "${var.cyclecloud_vnet}-to-cc"
  resource_group_name       = var.existing_vnet_rg
  virtual_network_name      = var.existing_vnet
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
  allow_gateway_transit     = true
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
