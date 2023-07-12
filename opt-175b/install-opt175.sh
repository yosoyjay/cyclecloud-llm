#!/bin/bash
# Installs environment to run OPT-175B training benchmarks.
set -o errexit
set -o nounset
set -o pipefail

# These env vars are used eventually
source nccl-env-var.sh

INSTALL_DIR=${INSTALL_DIR-$HOME}
SRC_DIR=`readlink -f .`
CONDA_DIR=/mnt/miniconda

printf "Downloading and installing software in ${INSTALL_DIR}"
pushd $INSTALL_DIR

printf "Installing conda"
curl -fsO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $CONDA_DIR

# Setup conda for shell use
$CONDA_DIR/bin/conda init `basename $SHELL`
# Cannot directly source .bashrc on Ubuntu from script, so just directly source the conda script
source $CONDA_DIR/etc/profile.d/conda.sh

conda create -y -c conda-forge --name fairseq python=3.9
conda activate fairseq

printf "Installing Python requirements"
#CUDA 11.3/11.4
#python -m pip install -r $SRC_DIR/requirements.txt -f https://download.pytorch.org/whl/torch_stable.html
#CUDA 12
python -m pip install -r $SRC_DIR/requirements.txt --pre -f https://download.pytorch.org/whl/nightly/cu121/torch_nightly.html

printf "Installing Apex"
git clone https://github.com/NVIDIA/apex
pushd apex
# Avoid CUDA extension + Pytorch complaint.  This is fine for CUDA 11.3 vs. 11.4
sed -i "s/check_cuda_torch_binary_vs_bare_metal(CUDA_HOME)//g" setup.py
python -m pip install -v --no-build-isolation --no-cache-dir --global-option="--cpp_ext" \
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
git checkout fairseq_v3
pip install -e .
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
git checkout fixing_memory_issues_with_keeping_overlap
pip install .
popd

printf "Be sure to run 'conda activate fairseq' and 'source nccl-env-var.sh' before running benchmarks"

popd
