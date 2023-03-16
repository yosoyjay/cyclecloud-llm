# Benchmark OPT-175B

Steps to benchmark training of OPT-175B on a Slurm cluster.

## Prerequisites

- A Slurm cluster with the appropriate VM (e.g. Standard_ND96amsr_A100_v4).

## Running the benchmark

### 0.  Connect to the scheduler, or login node if enabled

```bash
ssh <username>@<scheduler>
```

### 1. Install software requirements

#### 1a. Python environment

This benchmark is run on bare metal in a conda virtual environment following the instructions in the [Metaseq README](https://github.com/facebookresearch/metaseq/blob/main/docs/setup.md).

Install Python environemnt for this purpose using miniconda:

```bash
curl -fsO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
$HOME/miniconda/bin/conda init
```

Create and activate conda environment:

```bash
source $HOME/.bashrc
conda create -y -c conda-forge --name fairseq python=3.9
conda activate fairseq
```

Install the prerequisites, yes, via `pip`:

The the version of torch specified in the requirements should match the CUDA version of the VM.  Check CUDA version with `nvcc --version` and then install the appropriate version of torch, e.g.:
CUDA 11.6 -> torch==1.10.0+cu116.  Note that PyTorch packaged for CUDA 11.3 works with CUDA 11.4 (the version shipped with Ubuntu 18.04 HPC images), see [Github issue](https://github.com/pytorch/pytorch/issues/75992)]

```bash

```bash
pip install -r requirements.txt -f https://download.pytorch.org/whl/torch_stable.html
```

#### 1b. NVIDIA Apex

Install the Apex extension to PyTorch to enable mixed precision and distributed training optimizations.

In some cases, as in when VM CUDA version is 11.4 and PyTorch is 1.10.0+cu113, one must disable a check in the Apex setup script.  This is currently done by removing the line in the `setup.py` file as done with
the `sed` command below.

```bash
git clone https://github.com/NVIDIA/apex
pushd apex
sed -i "s/check_cuda_torch_binary_vs_bare_metal(CUDA_HOME)//g" setup.py
python -m pip install -v --no-cache-dir --global-option="--cpp_ext" \
    --global-option="--cuda_ext" \
    --global-option="--deprecated_fused_adam" \
    --global-option="--xentropy" \
    --global-option="--fast_multihead_attn" .
popd
```

#### 1c. Install Megatron

Install Megatron fork as specified in the aforementioned README.

```bash
git clone https://github.com/ngoyal2707/Megatron-LM.git
pushd Megatron-LM
git checkout fairseq_v3
pip install -e .
popd
```

#### 1e. Load NCCL environmental variables tuned for optimized distributed training

```bash
source nccl-env-var.sh
```

#### 1f. Install Metaseq

Ensure version includes commit a1a4e733.

```bash
git clone https://github.com/facebookresearch/metaseq.git
pushd metaseq
python setup.py build_ext --inplace
pip install -e .
popd
```

#### 1g. Install Fairscale

Note, this install via pip is not editable (i.e. no `-e`) as the `metaseq/train.py` checks the `fairscale` version which will not be defined if installed in editable mode.

```bash
git clone https://github.com/facebookresearch/fairscale.git
pushd fairscale
git checkout fixing_memory_issues_with_keeping_overlap
pip install .
popd
```

### 2. Run benchmark with synthetic data

Ensure Python environment is activated, e.g.:

```bash
conda activate fairseq
```

If on a stand-alone VM:

```bash
time opt-baselines --model-size 125m --benchmark -t 1 -g 8 -n 128 -p test-125m --local --azure
```

If on Slurm cluster using *NP* nodes:

```bash
time opt-baselines --model-size 125m --benchmark -t $NP -g 8 -n 128 -p test-125m --azure
```

On a single instance of a single Standard_ND96amsr_A100_v4 (8 x 80GB SMX A100) VM this took ~2.5 minutes with training words per seconds of at least 200K.
