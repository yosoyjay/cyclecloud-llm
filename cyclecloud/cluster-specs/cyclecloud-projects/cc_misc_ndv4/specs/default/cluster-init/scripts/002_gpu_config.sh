#!/bin/bash

chmod +x $CYCLECLOUD_SPEC_PATH/files/gpu_persistence_mode.sh
chmod +x $CYCLECLOUD_SPEC_PATH/files/max_gpu_app_clocks.sh
$CYCLECLOUD_SPEC_PATH/files/gpu_persistence_mode.sh
$CYCLECLOUD_SPEC_PATH/files/max_gpu_app_clocks.sh
