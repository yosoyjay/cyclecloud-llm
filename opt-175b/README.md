# Benchmark OPT-175B

This document describes the steps to prepare an environment and to benchmark the training of an OPT-175B model on a Slurm cluster deployed on Azure.

These directions assume that a a Slurm cluster with the appropriate VM (e.g. Standard_ND96amsr_A100_v4) has already been provisioned (See [README.md](../README.md) for details).

# Preparing the environment

Connect to the scheduler, or login node if enabled:

```bash
$ ssh <username>@<scheduler>
```

One step, the installation of the Apex library, requires a GPU, so it may be easier to run all of the commands from a compute node. To login to a compute node, run:

```bash
$ slogin <node-name>
```

## Step 1. Create Python environment

This benchmark is run on bare metal in a conda virtual environment following the instructions in the [Metaseq README](https://github.com/facebookresearch/metaseq/blob/main/docs/setup.md).

Install Python enviroment for this purpose using miniconda:

```bash
$ curl -fsO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
$ bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
$ $HOME/miniconda/bin/conda init
```

Create and activate conda environment:

```bash
$ source $HOME/.bashrc
$ conda create -y -c conda-forge --name fairseq python=3.9
$ conda activate fairseq
```

Install the prerequisites, yes, via `pip`:

The the version of torch specified in the requirements should match the CUDA version of the VM.  Check CUDA version with `nvcc --version` and then install the appropriate version of torch, e.g.:
CUDA 11.6 -> torch==1.10.0+cu116.  Note that PyTorch packaged for CUDA 11.3 works with CUDA 11.4 (the version shipped with Ubuntu 18.04 HPC images), see [Github issue](https://github.com/pytorch/pytorch/issues/75992).

```bash
$ pip install -r requirements.txt -f https://download.pytorch.org/whl/torch_stable.html
```

## Step 2. Install NVIDIA Apex to enable training optimizations

Install the Apex extension to PyTorch to enable mixed precision and distributed training optimizations.

In some cases, as in when VM CUDA version is 11.4 and PyTorch is 1.10.0+cu113, one must disable a check in the Apex setup script.  This is currently done by removing the line in the `setup.py` file as done with
the `sed` command below.

This step must be done on a device with a GPU, so log into a compute node if not already on one (e.g. `slogin slurm-hpc-pg0-1`). Then run the following commands:

```bash
$ git clone https://github.com/NVIDIA/apex
$ pushd apex
$ sed -i "s/check_cuda_torch_binary_vs_bare_metal(CUDA_HOME)//g" setup.py
$ python -m pip install -v --no-cache-dir --global-option="--cpp_ext" \
    --global-option="--cuda_ext" \
    --global-option="--deprecated_fused_adam" \
    --global-option="--xentropy" \
    --global-option="--fast_multihead_attn" .
$ popd
```

You can then go back to the scheduler node.

## Step 3. Install Megatron

Install Megatron fork as specified in the aforementioned README.

```bash
$ git clone https://github.com/ngoyal2707/Megatron-LM.git
$ pushd Megatron-LM
$ git checkout fairseq_v3
$ pip install -e .
$ popd
```

## Step 4. Install Metaseq

Ensure version includes commit a1a4e733.

```bash
$ git clone https://github.com/facebookresearch/metaseq.git
$ pushd metaseq
$ python setup.py build_ext --inplace
$ pip install -e .
$ popd
```

## Step 5. Install Fairscale

Note, this install via pip is not editable (i.e. no `-e`) as the `metaseq/train.py` checks the `fairscale` version which will not be defined if installed in editable mode.

```bash
$ git clone https://github.com/facebookresearch/fairscale.git
$ pushd fairscale
$ git checkout fixing_memory_issues_with_keeping_overlap
$ pip install .
$ popd
```

# Run benchmark with synthetic data

Ensure Python environment is activated, e.g.:

```bash
$ conda activate fairseq
```

Ensure that environmental variables are properly set for optimal performance:

```bash
$ source nccl-env-var.sh
```

If on a stand-alone VM specify a 125M parameter model as that will fit in memory:

```bash
$ time opt-baselines --model-size 125m --benchmark -t 1 -g 8 -n 128 -p test-125m --local --azure
```

If on Slurm cluster using *NP* nodes and model size of your choosing, e.g. 175B:

```bash
$ time opt-baselines --model-size 175b --benchmark -t $NP -g 8 -n 128 -p test-125m --azure
```

On a single instance of a single Standard_ND96amsr_A100_v4 (8 x 80GB SMX A100) VM this took ~2.5 minutes with a training rate of words per second of at least 200K.
