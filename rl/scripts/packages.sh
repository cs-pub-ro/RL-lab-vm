#!/bin/bash
set -e

# install prerequisites
echo "Installing / upgrading packages..." >&2

export DEBIAN_FRONTEND=noninteractive

# fix locale issues
locale-gen "en_US.UTF-8"
dpkg-reconfigure locales

apt-get update
apt-get -y upgrade
apt-get install -y open-vm-tools lxc bridge-utils tree tmux vim nano neovim \
	iproute2 ifupdown traceroute tcpdump rsync s-nail bash-completion \
	docker.io docker-compose

