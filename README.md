# Training LLM (or, any large scale model) on Azure using CycleCloud + Slurm

This repo contains the essential scripts, configurations, and instructions required to train a language language model (LLM) on Azure using CycleCloud to deploy a GPU (e.g. A100 or H100) cluster managed by Slurm.

Hardware details for the VMs appropriate for this deployment are available on [Microsoft Azure Documentation]:
- [NDasrA100](https://learn.microsoft.com/en-us/azure/virtual-machines/nda100-v4-series)
- [NDm_A100](https://learn.microsoft.com/en-us/azure/virtual-machines/ndm-a100-v4-series)
- [NDv5 (H100)](https://azure.microsoft.com/en-in/blog/azure-previews-powerful-and-scalable-virtual-machine-to-help-customers-accelerate-ai/)

The deployment and configuration of the cluster shown here is similar to those used to deploy and train O(100B++) parameter foundational LLMs on O(1K) GPUs, but is generally applicable for any AI workload using batch scheduling.

A few key features of this deployment are:
- Use of Terraform as Infrastructure-as-Code tool to deploy CycleCloud
- Use of Slurm as the batch scheduler
  - Support for container based workloads using [enroot](https://github.com/NVIDIA/enroot) and [pyxis](https://github.com/NVIDIA/pyxis)
  - Integration with [PMIx](https://pmix.github.io/) to support efficient large-scale training
  - Integration with [Node Health Check(NHC)](https://github.com/mej/nhc) to monitor and automatically detect common hardware issue that may slow down or stop the training
- Configuration for key variables supplied through environment variables
- Installation and configuration of CycleCloud and Slurm using [cloud-init](https://cloudinit.readthedocs.io/en/latest/)

Not demonstrated here for simplicity, but potentially useful, are:
- Use of Slurm accounting to track resource usage
- Use of Azure NetApp Files, or Azure Managed Lustre FS, as the shared filesystem for better performance if appropriate for your workload

## Prerequisites

Use of this repo requires the following:

- An Azure subscription
- [Terraform installed on your local machine](https://developer.hashicorp.com/terraform/tutorials/azure-get-started/install-cli)
- [Azure CLI installed on your local machine](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Terraform authenticated to your Azure subscription (See [Hashicorp docs](https://developer.hashicorp.com/terraform/tutorials/azure-get-started/azure-build) or [Microsoft docs](https://learn.microsoft.com/en-us/azure/developer/terraform/quickstart-configure#configure-in-azure-cloud-shell-with-bash))

## Provision and configure infrastructure

### Deploy CycleCloud

The deployment of CycleCloud is done using Terraform and is configured using environmental variables described `variables.tf`.  The variables without default values must be set and a template is provided in the file `.envrc.template` which can be copied to to `.envrc` to be used with [direnv](https://direnv.net/), or manually sourced (i.e. `source .envrc`).  Note, `.envrc` is listed in the `.gitignore` file so it will not be accidentally committed.

This deployment assumes that there is an existing virtual network and virtual network that can be peered to avoid using public IPs.

Once the required environmental variables are set, the deployment can be done by running the following commands:

```bash
$ terraform init
$ terraform plan -out=plan-main.out
$ terraform apply plan-main.out
```
This will provision:
- A resource group
- A virtual network and default subnet peered to the specified existing virtual network with a virtual network gateway
- A storage account and container configured to work with CycleCloud (without hierarchical namespace) and access to your local machine and the newly provisioned virtual network
- A user managed identity with the role of `Contributor` on the resource group which will be assigned to compute nodes to allow them to access the storage account or other Azure resources

Once that has completed, connect to the existing virtual network gateway (VPN), even if you were connected before, and deploy the CycleCloud VM by running the following commands:

```bash
$ terraform plan -out=plan-vm.out -var "create_cyclecloud_vm=true"
$ terraform apply plan-vm.out
```

This will provision:
- A VM with CycleCloud installed which will provide administrative access through a web browser and SSH

### Start the Slurm cluster

Once the CycleCloud VM is provisioned, you can login to the CycleCloud web interface at the IP address (e.g. 10.50.0.4:8080) of the VM using the credentials provided through the environmental variables and will be output at the end of the VM provisioning logs.  Once logged in, verify the desired configuration of the cluster by pressing the `Edit` button on the `Cluster` page.

In particular, verify the following:

- "Required Settings":
    - "MSI Identify" is configured with "cyclecloud-node" (defined in `main.tf`)
    - "HPC VM Type" is the desired type
    - "Max HPC Cores" is the desired number of cores for the cluster (NDv4 have 96 cores, so 192 cores would be 2 nodes and 16 A100 GPUs)
    - "Max VMs per Scale Set" is the desired number of VMs per scale set (Max can be 300 unless you've made other special arrangements)
    - "Subnet ID" is the subnet ID of the default subnet created by Terraform

- "Network Attached Storage", the shared NFS configuration:
    - "Size (GB)" is the desired size of the shared filesystem. This is the total size of the filesystem used for home directories, not the local scratch space on the VMs.

- "Advanced Settings":
    - "Credentials" are the correct and match what you provided through the environmental variables
    - "{Scheduler, Login Cluster, HP Cluster}-init" include appropriate projects.
        - "cc_misc_ndv4", "cc_slurm_nhc", "cc_slurm_pyxis_enroot" is appropriate for compute VMs
        - "cc_misc_ubuntu" is appropriate for all vms
    - "Public Head Node" - check if public IP is for scheduler is desired

Then start the cluster by pressing the `Start` button on the `Cluster` page.  You can also start the cluster from the command line on the CycleCloud VM after SSHing to that VM using the following command:

```bash
ccadmin@cyclecloud-vm$ cyclecloud cluster start -c slurm
```

The scheduler node will take a few minutes to start.  The compute nodes will need to be manually started by right-clicking the "hpc" labeled row under "Template" and selecting "Start" from the "Actions" pull-down menu.  Note that provisioning NDv4 VMs can take up to 20 minutes.

### Verify cluster performance

An essential component of training at scale is the ability to monitor and detect hardware issues.  To verify that the cluster is configured and operating as expected, [Node Health Checks](https://github.com/mej/nhc) are deployed and configured as part of the CycleCloud deployment.  Included in this are checks on each node for:
- disk issues
- IB network issues
- NCCL bandwidth issues
- GPU issues

To verify optimal performance when using distributed training, [NCCL tests](https://github.com/NVIDIA/nccl-tests) can also be run to measure the bandwidth between nodes and GPUs on the cluster.
Here we use a set of scripts that allow us to verify distributed all-reduce performance on the cluster using scripts from [the azurehpc collection of scripts](https://github.com/Azure/azurehpc/tree/master/experimental/run_nccl_tests_ndv4).

Specifically, we can test NCCL tests without Slurm, using Slurm, and using Slurm with containers.

Running NCCL tests without Slurm, you need to SSH to a compute node and run the following commands from `nccl-tests` directory:

```bash
# to test on two nodes (16 GPUs)
$ all-reduce.sh 16 hostfiles.txt
```

A convenience script `make-hostfile.py` is provided to create a hostfile from output of `sinfo`.

Running NCCL tests with Slurm on N nodes (e.g. `-N 2` to use 16 total GPUs):

```bash
$ sbatch -N $N all-reduce.sh
```

Running NCCL tests with Slurm and containers on N nodes:

```bash
$ sbatch -N $N all-reduce-containers.sh
```

A well running cluster should have a bandwidth of 185 GB/s or more for two or more nodes.

## Benchmarking / training a Language Language Model (OPT-175B, as an example)

As an example, we'll benchmark a smaller 175M parameter version of a 175B parameter LLM on 16 A100 GPUs using [Metaseq](https://github.com/facebookresearch/metaseq) and following the directions in the [Metaseq README](https://github.com/facebookresearch/metaseq/blob/main/docs/setup.md).

Details for setup and running the benchmark are provided in the [opt-175b README](opt-175b/README.md).
