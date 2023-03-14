#!/bin/bash
# Upon reboot of the VM:
# - mount the NVMe disks
# - set the GPU application clock to max
# - set the GPU persistence mode to 1
set -o errexit
set -o nounset
set -o pipefail

SCRIPTS_DIR=/root

if [ -b /dev/md127 ]; then
   DEV=/dev/md127
elif [ -b /dev/md128 ]; then
   DEV=/dev/md128
else
   ${SCRIPTS_DIR}/setup_nvme_heal.sh
fi

if [ -n "$DEV" ]; then
   mount $DEV /mnt/resource_nvme
fi

${SCRIPTS_DIR}/max_gpu_app_clocks.sh
nvidia-smi -pm 1
