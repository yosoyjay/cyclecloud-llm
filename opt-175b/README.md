# Benchmark OPT-175B

Scripts to benchmark training of OPT-175B on a CycleCloud SLURM cluster.

## Prerequisites

- An appropriate VM, or
- A CycleCloud SLURM cluster with the appropriate VM (e.g. Standard_ND96amsr_A100_v4)

## Running the benchmark

### 0. [If on a SLURM cluster] Connect to the worker node

 ssh <private-ip>
 cyclecloud connect <node-name> -c <cluster-name>

### 1. Install software requirements

#### 1a. Python environment

The benchmark is run on bare metal in a conda virtual environment.

Install conda (here I use micromamba which has a superior dependency resolver compared to the default one provided by conda):

```bash
curl micro.mamba.pm/install.sh | bash
```

Create and activate conda environment:

```bash
source /shared/home/hpcadmin/.bashrc
micromamba create -y -c conda-forge --name fairseq python=3.9
micromamba activate fairseq
```

Install prereqs with `pip` !?!?

```bash
pip install -r requirements.txt
```

#### 1b. NVIDIA Apex

Install Apex for utilities for mixed precision and distributed training optimizations.

```bash
git clone https://github.com/NVIDIA/apex
pushd apex
sed -i "s/(bare_metal_major != torch_binary_major) or (bare_metal_minor != torch_binary_minor)/False/g" setup.py
python -m pip install -v --no-cache-dir --global-option="--cpp_ext" \
    --global-option="--cuda_ext" \
    --global-option="--deprecated_fused_adam" \
    --global-option="--xentropy" \
    --global-option="--fast_multihead_attn" .
popd
```

#### 1c. Install Megatron

Install Megatron fork (why?):

```bash
git clone https://github.com/ngoyal2707/Megatron-LM.git
pushd Megatron-LM
git checkout fairseq_v2
pip install -e
popd
```

#### 1d. Install NCCL

```bash
git clone https://github.com/NVIDIA/nccl.git
pushd nccl
make clean && make -j src.build
popd
```

#### 1e. Load environmental variables

```bash
source envrc
```

#### 1f. Install Metaseq

Ensure version includes commit a1a4e733.

```bash
git clone https://github.com/facebookresearch/metaseq.git
pushd metaseq
git log | grep "a1a4e733"
python setup.py build_ext --inplace
pip install -e .
popd
```

#### 1g. Install Fairscale

Note, this install via pip is not editable (i.e. no `-e`) as the `metaseq/train.py` checks the `fairscale` version which will not be defined if installed in editable mode.

```bash
git clone https://github.com/facebookresearch/fairscale.git
pushd fairscale
git checkout fixing_memory_issues_with_keeping_overla
pip install .
popd
```

### 2. Run benchmark

Ensure Python environment is activated, e.g.:

```bash
micromamba activate fairseq
```

If on a stand-alone VM:

```bash
time opt-baselines --model-size 125m --benchmark -t 1 -g 8 -n 128 -p test-125m --local --azure
```

If on the SLURM log-in node:

```bash
time opt-baselines --model-size 125m --benchmark -t 1 -g 8 -n 128 -p test-125m --local --azure
```

On a single instance of a signle Standard_ND96amsr_A100_v4 VM this took ~2.5 minutes with WPS of at least 200K.
