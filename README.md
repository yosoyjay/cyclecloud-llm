# Training LLM on Azure using CycleCloud + Slurm

This repo contains the essential scripts, configurations, and instructions required to train a language language model (LLM) on Azure using CycleCloud to deploy a Slurm cluster comprised of NDv4 VMs each of which are are equipped with 8 A100 (40 GB or 80 GB) GPUs, 8 HDR InfiniBand 200 Gbps network cards, 96 vCPUs, at least 900 GB of memory, and at least 6 TB of local NVMe SSD storage.
Details of the hardware details for [NDasrA100](https://learn.microsoft.com/en-us/azure/virtual-machines/nda100-v4-series) and [NDm_A100](https://learn.microsoft.com/en-us/azure/virtual-machines/ndm-a100-v4-series) VMs are available on [Microsoft Azure Documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/).

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

## Deployment

### Deploy CycleCloud

The deployment of CycleCloud is done using Terraform and is configured using environmental variables described `variables.tf`.  The variables without default values must be set and a template is provided in the file `.envrc.template` which can be modified and renamed to `.envrc` to be used with [direnv](https://direnv.net/), or manually sourced.

After the required environmental variables are set, the deployment can be done by running the following commands:

```bash
$ terraform init
$ terraform plan -out=plan.out
$ terraform apply plan.out
```

This will provision:
- A resource group
- A virtual network and default subnet
- A storage account and container configured to work with CycleCloud (no hierarchical namespace) and access to your local machine and the newly provisioned virtual network
- A user managed identity with the role of `Contributor` on the resource group which will be assigned to compute nodes to allow them to access the storage account or other Azure resources
- A VM with CycleCloud installed which will provide administrative access through a web browser and SSH

### Start the Slurm cluster

Once the CycleCloud VM is provisioned, you can login to the CycleCloud web interface at the IP address of the VM using the credentials provided through the environmental variables.  Once logged in, verify the desired configuration of the cluster by pressing the `Edit` button on the `Cluster` page.

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
    - "Credentials" is the correct that you provided through the environmental variables
    - "{Scheduler, Login Cluster, HP Cluster}-init" included appropriate projects.
        - "cc_misc_ndv4", "cc_slurm_nhc", "cc_slurm_pyxis_enroot" is appropriate for compute VMs
        - "cc_misc_ubuntu" is appropriate for all vms
    - "Public Head Node" - check if public IP is for scheduler is desired

Then start the cluster by pressing the `Start` button on the `Cluster` page.  You can also start the cluster from the command line on the CycleCloud VM after SSHing to that VM using the following command:

```bash
ccadmin@cyclecloud-vm$ cyclecloud cluster start -c Slurm
```

The scheduler node will take a few minutes to start.  The compute nodes will need to be manually started and can take up to 20 minutes to fully provision.


## Training a Language Language Model (OPT-175B, as an example)

As an example, we'll train a 175B parameter LLM on 16 A100 GPUs using [Metaseq](https://github.com/facebookresearch/metaseq) and following the directions in the [Metaseq README](https://github.com/facebookresearch/metaseq/blob/main/docs/setup.md).