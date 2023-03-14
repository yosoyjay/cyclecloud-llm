{
  "Region" : "${location}",
  "Credentials" : "${subscription_id}",
  "SubnetId" : "${resource_group_name}/${vnet_name}/${subnet_name}",
  "UsePublicNetwork" : "${use_public_network}",
  "ExecuteNodesPublic" : false,
  "EnableAccelNet": true,
  "NodeNameIsHostname" : true,
  "NodeNamePrefix" : "Cluster Prefix",
  "ReturnProxy" : false,
  "ManagedServiceIdentity": "${managed_service_id}",
  "SchedulerMachineType" : "Standard_D32as_v4",
  "SchedulerImageName" : "${vm_image}",
  "SchedulerHostName" : "Cluster Prefix",
  "SchedulerClusterInitSpecs" : {
    "cc_slurm_pyxis_enroot:default:1.0.0" : {
      "Order" : 10000,
      "Spec" : "default",
      "Name" : "cc_slurm_pyxis_enroot:default:1.0.0",
      "Project" : "cc_slurm_pyxis_enroot",
      "Locker" : "${cyclecloud_locker}",
      "Version" : "1.0.0"
    },
    "cc_slurm_nhc:default:1.0.0" : {
      "Order" : 10100,
      "Spec" : "default",
      "Name" : "cc_slurm_nhc:default:1.0.0",
      "Project" : "cc_slurm_nhc",
      "Locker" : "${cyclecloud_locker}",
      "Version" : "1.0.0"
    },
    "cc_misc_ubuntu:default:1.0.0" : {
      "Order" : 10200,
      "Spec" : "default",
      "Name" : "cc_misc_ubuntu:default:1.0.0",
      "Project" : "cc_misc_ubuntu",
      "Locker" : "${cyclecloud_locker}",
      "Version" : "1.0.0"
    }
  },
  "Autoscale" : false,
  "NFSSchedDisable" : false,
  "slurm" : null,
  "configuration_slurm_version" : "20.11.7-1",
  "configuration_slurm_ha_enabled" : false,
  "configuration_slurm_shutdown_policy" : "Terminate",
  "configuration_slurm_accounting_enabled" : false,
  "configuration_slurm_accounting_url" : "<NOT-SET>",
  "configuration_slurm_accounting_user" : "<NOT-SET>",
  "configuration_slurm_accounting_password" : "<NOT-SET>",
  "additional_slurm_config" : "SuspendTime=-1",
  "loginMachineType" : "Standard_D32as_v4",
  "NumberLoginNodes" : 2,
  "LoginClusterInitSpecs": {
    "cc_limits:default:1.0.0" : {
      "Order" : 10000,
      "Spec" : "default",
      "Name" : "cc_limits:default:1.0.0",
      "Project" : "cc_limits",
      "Locker" : "${cyclecloud_locker}",
      "Version" : "1.0.0"
    },
    "cc_misc_ubuntu:default:1.0.0" : {
      "Order" : 10100,
      "Spec" : "default",
      "Name" : "cc_misc_ubuntu:default:1.0.0",
      "Project" : "cc_misc_ubuntu",
      "Locker" : "${cyclecloud_locker}",
      "Version" : "1.0.0"
    },
    "cc_slurm_pyxis_enroot:default:1.0.0" : {
      "Order" : 10400,
      "Spec" : "default",
      "Name" : "cc_slurm_pyxis_enroot:default:1.0.0",
      "Project" : "cc_slurm_pyxis_enroot",
      "Locker" : "${cyclecloud_locker}",
      "Version" : "1.0.0"
    }
  },
  "HPCImageName" : "microsoft-dsvm:ubuntu-hpc:1804:18.04.2021120101",
  "HPCMachineType" : "Standard_ND96amsr_A100_v4",
  "MaxHPCExecuteCoreCount" : 192,
  "HPCMaxScalesetSize" : 100,
  "HPCMemoryDampen": 8,
  "HPCClusterInitSpecs" : {
    "cc_slurm_pyxis_enroot:default:1.0.0" : {
      "Order" : 10000,
      "Spec" : "default",
      "Name" : "cc_slurm_pyxis_enroot:default:1.0.0",
      "Project" : "cc_slurm_pyxis_enroot",
      "Locker" : "${cyclecloud_locker}",
      "Version" : "1.0.0"
    },
    "cc_slurm_nhc:default:1.0.0" : {
      "Order" : 10100,
      "Spec" : "default",
      "Name" : "cc_slurm_nhc:default:1.0.0",
      "Project" : "cc_slurm_nhc",
      "Locker" : "${cyclecloud_locker}",
      "Version" : "1.0.0"
    },
    "cc_misc_ndv4:default:1.0.0" : {
      "Order" : 10200,
      "Spec" : "default",
      "Name" : "cc_misc_ndv4:default:1.0.0",
      "Project" : "cc_misc_ndv4",
      "Locker" : "${cyclecloud_locker}",
      "Version" : "1.0.0"
    }
  },
  "NFSAddress" : null,
  "NFSType" : "Builtin",
  "NFSSharedExportPath" : "/shared",
  "NFSSharedMountOptions" : "rw,hard,rsize=262144,wsize=262144,nconnect=8,sec=sys,vers=4.1,tcp",
  "About shared" : null,
  "AdditionalNAS" : false,
  "AdditonalNFSAddress" : "<NOT-SET>",
  "AdditionalNFSExportPath" : "<NOT-SET>",
  "AdditionalNFSMountOptions" : "rw,hard,rsize=262144,wsize=262144,nconnect=8,sec=sys,vers=4.1,tcp",
  "AdditionalNFSMountPoint" : "/scratch",
  "Additional NFS Mount Readme" : null
}
