variable "local_ip_address" {
  description = "Local IP address to allow access to storage account"
  type        = string
}

variable "storage_location" {
  description = "Location for storage account"
  type        = string
}

variable "storage_resource_group" {
  description = "Resource group for storage account"
  type        = string
}

variable "cyclecloud_location" {
  description = "Location for CycleCloud"
  type        = string
}

variable "cyclecloud_resource_group" {
  description = "Resource group for CycleCloud"
  type        = string
}

variable "cyclecloud_vnet" {
  description = "Vnet for CycleCloud"
  type        = string
}

variable "cyclecloud_subnet" {
  description = "Subnet for CycleCloud"
  type        = string
}

variable "cyclecloud_vnet_address_space" {
  description = "Vnet address space for CycleCloud"
  type        = string
}

variable "cyclecloud_subnet_address_prefix" {
  description = "Subnet address prefix for CycleCloud"
  type        = string
}

variable "cyclecloud_storage_account" {
  description = "Storage account name for CycleCloud"
  type        = string
}

variable "cyclecloud_storage_container" {
  description = "Storage container name for CycleCloud"
  type        = string
}

variable "cyclecloud_vm_name" {
  description = "Name given to the cyclecloud vm and used to prefix other resources"
  type        = string
  default     = "cyclecloud-vm"
}

variable "cyclecloud_vm_size" {
  description = "CycleCloud VM SKU"
  type        = string
  default     = "Standard_B2ms"
}

variable "cyclecloud_user_data" {
  description = "Path to cloud-init user data to pass to the VM"
  type        = string
  default     = "user-data.yaml.tpl"
}
variable "cyclecloud_admin_name" {
  description = "CycleCloud admin user name"
  type        = string
}
variable "cyclecloud_admin_password" {
  description = "CycleCloud admin user password"
  type        = string
}

variable "cyclecloud_subscription_name" {
  description = "Name of subscription/account used within CycleCloud"
  type        = string
}

variable "cyclecloud_vm_image" {
  description = "VM image to use on compute nodes"
  type        = string
  default     = "microsoft-dsvm:ubuntu-hpc:2004:20.04.2022121201"
}

variable "public_key" {
  description = "Name of public key"
  type        = string
}

variable "public_key_path" {
  description = "Path to public key use for SSH access to VMs"
  type        = string
}

variable "use_public_network" {
  description = "Enable public accesss to CycleCloud cluster"
  type        = bool
  default     = false
}

variable "private_key_path" {
  description = "Path to private key to use for SSH access to VMs"
  type        = string
}

variable "existing_vnet" {
  description = "Name of an existing virtual network that will be peered to and used as remote gateway"
  type        = string
}

variable "existing_vnet_rg" {
  description = "Name of the resource group that contains the existing virtual network"
  type        = string
}

variable "create_cyclecloud_vm" {
  description = "Create CycleCloud VM"
  type        = bool
  default     = false
}
