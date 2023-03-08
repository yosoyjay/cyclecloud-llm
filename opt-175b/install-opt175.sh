#!/bin/bash
# Installs environment to run OPT-175B training benchmarks.

set -o errexit
set -o nounset
set -o pipefail

# These envvars are used eventually
source .envrc

INSTALL_DIR=${INSTALL_DIR-'/shared/home/hpcadmin'}
SRC_DIR=`readlink -f .`

printf "Downloading and installing software in ${INSTALL_DIR}"
pushd $INSTALL_DIR

printf "Installing micromamba"
curl micro.mamba.pm/install.sh | bash
source /shared/home/hpcadmin/.bashrc
micromamba create -y -c conda-forge --name fairseq python=3.9
micromamba activate fairseq

printf "Installing Python requirements"
pip install -r "${SRC_DIR}/requirements.txt"

printf "Installing Apex"
git clone https://github.com/NVIDIA/apex
pushd apex
# Avoid CUDA extension + Pytorch complaint.  This is okay on Azure VMs. 
sed -i "s/(bare_metal_major != torch_binary_major) or (bare_metal_minor != torch_binary_minor)/False/g" setup.py
python -m pip install -v --no-cache-dir --global-option="--cpp_ext" \
    --global-option="--cuda_ext" \
    --global-option="--deprecated_fused_adam" \
    --global-option="--xentropy" \
    --global-option="--fast_multihead_attn" .
popd

printf "Installing NCCL"
git clone https://github.com/NVIDIA/nccl.git
pushd nccl
make clean && make -j src.build
popd

printf "Installing Megatron fork"
git clone https://github.com/ngoyal2707/Megatron-LM.git
pushd Megatron-LM
git checkout fairseq_v2
pip install -e
popd

printf "Installing Metaseq"
git clone https://github.com/facebookresearch/metaseq.git
pushd metaseq
git log | grep "a1a4e733"
python setup.py build_ext --inplace
pip install -e .
popd

printf "Installing Fairscale"
git clone https://github.com/facebookresearch/fairscale.git
pushd fairscale
git checkout fixing_memory_issues_with_keeping_overla
pip install .
popd 

popd