#!/usr/bin/env bash
# Bootstrap storage to store Terraform state by creating Storage Account and Container.
set -e
set -o pipefail
set -o nounset

printf "Bootstrapping storage for Terraform state\n"

printf "Creating resource group '%s' for terraform state\n" "$TF_VAR_storage_resource_group"
az group create \
    --name "$TF_VAR_storage_resource_group" \
    --location "$TF_VAR_storage_location" \
    --output none

printf "Creating storage account %s\n" "$TF_VAR_storage_account"
az storage account create \
    --name "$TF_VAR_storage_account" \
    --resource-group "$TF_VAR_storage_resource_group" \
    --location "$TF_VAR_storage_location" \
    --sku Standard_LRS \
    --encryption-services blob \
    --https-only true \
    --kind StorageV2 \
    --access-tier Hot \
    --output none

printf "Creating storage container %s\n" "$TF_VAR_storage_container"
az storage container create \
    --name "$TF_VAR_storage_container" \
    --account-name "$TF_VAR_storage_account" \
    --auth-mode login \
    --output none