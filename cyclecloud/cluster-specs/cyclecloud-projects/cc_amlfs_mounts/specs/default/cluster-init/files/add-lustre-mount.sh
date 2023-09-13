#!/bin/bash
# Adds a mount for the Lustre file system.
# Requires argument for the MGS endpoint IP.
set -ex
set -o nounset

MOUNT_POINT=/lustre
MGS_ENDPOINT_IP=10.22.0.23


echo "Adding Lustre mount ('${MOUNT_POINT}') to /etc/fstab using MGS endpoint IP: ${MGS_ENDPOINT_IP}"
mkdir -p $MOUNT_POINT
chmod 777 $MOUNT_POINT

mount -t lustre -o noatime,flock $MGS_ENDPOINT_IP@tcp:/lustrefs $MOUNT_POINT

# Edit /etc/fstab
echo "$MGS_ENDPOINT_IP@tcp:/lustrefs $MOUNT_POINT lustre noatime,flock 0 0" | tee -a /etc/fstab
