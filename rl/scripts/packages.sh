#!/bin/bash
set -e

# install prerequisites
echo "Installing / upgrading packages..." >&2

export DEBIAN_FRONTEND=noninteractive

apt-get update

# remove older kernels
apt-get --purge autoremove
# terminal / networking / utilities
apt-get install -y tree tmux vim nano neovim traceroute tcpdump rsync \
	s-nail bash-completion telnet dnsutils iptables-persistent

# containers
apt-get install -y lxc bridge-utils docker.io docker-compose

