#!/bin/bash
# Set GPU persistence mode
set -o errexit

nvidia-smi -pm 1
