#!/bin/bash
#SBATCH -t 00:20:00
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=12
#SBATCH --gpus-per-node=8
#SBATCH --exclusive

BASE_DIR=/opt
NCCL_TESTS_EXE=all_reduce_perf

source nccl-env-var.sh

CONT="nvcr.io#nvidia/pytorch:23.02-py3"
PIN_MASK='ffffff000000,ffffff000000,ffffff,ffffff,ffffff000000000000000000,ffffff000000000000000000,ffffff000000000000,ffffff000000000000'
MOUNT="/opt/microsoft:/opt/microsoft,$BASE_DIR/nccl-tests"

srun --mpi=pmix \
    --cpu-bind=mask_cpu:$PIN_MASK \
    --container-image "${CONT}" \
    --container-name=pytorch \
    --container-mounts "${MOUNT}" \
    ${BASE_DIR}/nccl-tests/build/$NCCL_TESTS_EXE -b 8 -f 2 -g 1 -e 8G -c 1
