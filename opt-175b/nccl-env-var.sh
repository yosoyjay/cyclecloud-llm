export CUDA_DEVICE_ORDER=PCI_BUS_ID
export NCCL_IB_PCI_RELAXED_ORDERING=1
export NCCL_SOCKET_IFNAME=eth0
export NCCL_TOPO_FILE=/opt/microsoft/ndv4-topo.xml
export OMPI_MCA_coll_hcoll_enable=0
export UCX_IB_PCI_RELAXED_ORDERING=on
export UCX_NET_DEVICES=eth0
# Some skus do not have sufficient disk space to build conda env for OPT.
# To avoid problems, specify the cache on the ephemeral disk
export PIP_CACHE_DIR=/mnt/.cache/pip
export INSTALL_DIR=/mnt/opt
export TMPDIR=/mnt/tmp
