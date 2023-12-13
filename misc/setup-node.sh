#!/bin/bash
# Setup for for training
# - Creates dirs on /mnt for Docker, enroot, and used for training data
# - Configures Docker to use /mnt/docker for container storage
# - Configures enroot to use /mnt/enroot for container storage
# - Clones Megatron-LM repo to /mnt
# - Saves training data to /mnt/data (requires AZURE_BLOB_URL to be set - see cycle-keyvault)

# Create dirs for data (containers), pretrain_data, and enroot
mkdir -p /mnt/{docker,data,enroot,checkpoints}
chmod 777 -R /mnt

# Save containers to /mnt/docker
cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
jq '. + {"data_dir": "/mnt/docker"}' /etc/docker/daemon.json > /etc/docker/daemon.json.tmp
mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json

# Edit config for enroot
export ENROOT_DATA_PATH=/mnt/enroot
export ENROOT_TEMP_PATH=/mnt/enroot/tmp

# Get Megatron-LM repo
git clone https://github.com/NVIDIA/Megatron-LM.git  /mnt

# Get the data
wget -P /mnt/data https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json
wget -P /mnt/data https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
azcopy copy \
    $AZURE_BLOB_URL \
    /mnt/data/codeparrot
