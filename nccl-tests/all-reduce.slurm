#!/bin/bash
#SBATCH -t 00:20:00
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=12
#SBATCH --gpus-per-node=8
#SBATCH --mem=0
#SBATCH -o %x_%j.log

BASE_DIR=/opt
NCCL_TESTS_EXE=all_reduce_perf

source nccl-env-var.sh
source /etc/profile.d/modules.sh
module load mpi/hpcx

PIN_MASK='ffffff000000,ffffff000000,ffffff,ffffff,ffffff000000000000000000,ffffff000000000000000000,ffffff000000000000,ffffff000000000000'

srun --mpi=pmix \
    --cpu-bind=mask_cpu:$PIN_MASK \
    --gpus-per-node=8 \
    --ntasks-per-node=8 \
    ${BASE_DIR}/nccl-tests/build/$NCCL_TESTS_EXE -b 8 -f 2 -g 1 -e 8G -c 1
