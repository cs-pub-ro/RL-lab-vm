#!/bin/bash
set -e

# install prerequisites
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y open-vm-tools lxc tree tmux vim neovim \
	iproute2 ifupdown traceroute tcpdump rsync s-nail

#lxc-create -t download -n red -- --dist=ubuntu --release=bionic --arch=amd64 \
#	--keyserver hkp://p80.pool.sks-keyservers.net:80

# https://us.images.linuxcontainers.org/
# https://www.alibabacloud.com/blog/how-to-install-and-configure-lxc-container-on-ubuntu-16-04_594090

