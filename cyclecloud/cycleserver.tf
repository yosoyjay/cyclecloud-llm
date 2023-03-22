#
# Prepare slurm config
#
resource "local_file" "slurm_config" {
  content = templatefile("cluster-specs/slurm/slurm.json.tpl", {
    location            = azurerm_resource_group.rg.location
    subscription_id     = var.cyclecloud_subscription_name
    resource_group_name = azurerm_resource_group.rg.name
    vnet_name           = azurerm_virtual_network.vnet.name
    subnet_name         = azurerm_subnet.subnet.name
    use_public_network  = var.use_public_network
    managed_service_id  = azurerm_user_assigned_identity.cyclecloud_node.id
    vm_image            = var.cyclecloud_vm_image
    # When subscription/account is created.  A locker is created with name "<subscription>-storage"
    cyclecloud_locker = "${var.cyclecloud_subscription_name}-storage"
  })
  filename = "cluster-specs/slurm/slurm.json"
}

#
# cloud-init user data
#
data "cloudinit_config" "cyclecloud_user_data" {
  gzip          = false
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile(var.cyclecloud_user_data, {
      cyclecloud_admin_name     = var.cyclecloud_admin_name
      cyclecloud_admin_password = var.cyclecloud_admin_password
      # Remove trailing newline from public key which causes yaml formatting issues
      cyclecloud_admin_public_key  = chomp(azurerm_ssh_public_key.public_key.public_key)
      cyclecloud_rg                = azurerm_resource_group.rg.name
      cyclecloud_location          = azurerm_resource_group.rg.location
      cyclecloud_storage_account   = var.cyclecloud_storage_account
      cyclecloud_storage_container = var.cyclecloud_storage_container
      cyclecloud_subscription_name = var.cyclecloud_subscription_name
      azure_subscription_id        = data.azurerm_subscription.current.subscription_id
      azure_tenant_id              = data.azurerm_subscription.current.tenant_id
    })
  }
}

# Create a new test VM + NIC
resource "azurerm_network_interface" "cyclecloud_nic" {
  name                    = "${var.cyclecloud_vm_name}-nic"
  internal_dns_name_label = var.cyclecloud_vm_name
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.cyclecloud_vm_name}-ip"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "cyclecloud_vm" {
  count               = var.create_cyclecloud_vm == true ? 1 : 0
  name                = var.cyclecloud_vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [
    azurerm_network_interface.cyclecloud_nic.id
  ]
  vm_size = var.cyclecloud_vm_size

  storage_os_disk {
    name              = "${var.cyclecloud_vm_name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 30
  }
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "ubuntu-hpc"
    sku       = "2004"
    version   = "latest"
  }
  os_profile {
    computer_name  = var.cyclecloud_vm_name
    admin_username = var.cyclecloud_admin_name
    custom_data    = data.cloudinit_config.cyclecloud_user_data.rendered
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = azurerm_ssh_public_key.public_key.public_key
      path     = "/home/${var.cyclecloud_admin_name}/.ssh/authorized_keys"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Less than ideal way to copy files to the VM without using more tools
  # - files are too big to fit in user_data
  provisioner "file" {
    source      = "cluster-specs/"
    destination = "/home/${var.cyclecloud_admin_name}"
  }
  connection {
    type        = "ssh"
    host        = azurerm_network_interface.cyclecloud_nic.private_ip_address
    user        = var.cyclecloud_admin_name
    private_key = file(var.private_key_path)
    agent       = false
  }
}

resource "azurerm_role_assignment" "cyclecloud_contributor" {
  count                = var.create_cyclecloud_vm == true ? 1 : 0
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"

  # Identities are lists, so index into the first one
  principal_id = azurerm_virtual_machine.cyclecloud_vm[0].identity[0].principal_id
}

output "cyclecloud_vm_ip" {
  value = azurerm_network_interface.cyclecloud_nic.private_ip_address
}
