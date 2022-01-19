#!/bin/bash
set -e

# install prerequisites
echo "Installing / upgrading packages..." >&2

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install --no-install-recommends -y apt-transport-https ca-certificates \
	curl software-properties-common

# terminal / networking / utilities
apt-get install --no-install-recommends -y tree tmux vim nano neovim traceroute \
	tcpdump dsniff rsync s-nail mailutils sharutils bash-completion telnet \
	dnsutils ftp iptables-persistent nmap whois elinks

# tools
apt-get install --no-install-recommends -y bridge-utils
# official docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt-get update
apt-get install -y docker-ce docker-compose
# docker without sudo
usermod -aG docker student || true

# enable docker
systemctl enable docker
systemctl restart docker

