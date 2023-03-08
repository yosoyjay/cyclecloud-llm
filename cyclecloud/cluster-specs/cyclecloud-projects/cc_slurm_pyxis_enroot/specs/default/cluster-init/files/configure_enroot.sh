#!/bin/bash

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

function create_enroot_config() {
   mv /etc/enroot/enroot.conf /etc/enroot/enroot.conf.bak
   cp ${CYCLECLOUD_SPEC_PATH}/files/enroot.conf /etc/enroot/enroot.conf
}

function create_mountpoints() {
   mkdir -pv /run/enroot /mnt/resource/{enroot-cache,enroot-data,enroot-temp}
   chmod -v 777 /run/enroot /mnt/resource/{enroot-cache,enroot-data,enroot-temp}
}

# Only in compute nodes
if ! is_slurm_controller; then
   create_enroot_config
   create_mountpoints
fi
