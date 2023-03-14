#!/bin/bash
# Install PMIx

set -o errexit
set -o nounset

cd ~/
mkdir -p /opt/pmix/v3
apt install -y libevent-dev
tar xvf $CYCLECLOUD_SPEC_PATH/files/openpmix-3.1.6.tar.gz
cd openpmix-3.1.6
./autogen.sh
./configure --prefix=/opt/pmix/v3
make -j install >/dev/null