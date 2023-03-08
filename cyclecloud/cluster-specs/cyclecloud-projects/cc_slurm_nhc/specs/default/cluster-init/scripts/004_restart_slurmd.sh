#!/bin/bash

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

if ! is_slurm_controller; then
    pkill -9 -f /usr/sbin/nhc
    systemctl restart slurmd
fi
