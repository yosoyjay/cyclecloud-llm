#!/bin/bash
# From: https://learn.microsoft.com/en-us/azure/azure-managed-lustre/install-ubuntu-20
set -ex

# Add Microsoft apt repo and update
apt update && apt install -y ca-certificates curl apt-transport-https lsb-release gnupg
source /etc/lsb-release
echo "deb [arch=amd64] https://packages.microsoft.com/repos/amlfs-${DISTRIB_CODENAME}/ ${DISTRIB_CODENAME} main" | tee /etc/apt/sources.list.d/amlfs.list
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
apt update

# Install Lustre client
sudo apt install -yq amlfs-lustre-client-2.15.1-24-gbaa21ca=$(uname -r)