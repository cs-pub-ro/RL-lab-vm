#!/bin/bash
# LXC configuration script
# To be ran inside the containers, as root
set -e
set -x

export SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
i=$1

echo "Waiting for container to boot..."
while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] && \
	[ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do sleep 1; done

echo "Setting up connectivity..."
# setup IP connectivity
ip addr add "10.90.$i.2/24" dev eth0
ip ro add default via "10.90.$i.1"
echo "nameserver 1.1.1.1" > /etc/resolv.conf
ping -c 4 -i 0.1 8.8.8.8

# rename users and passwords
if id "ubuntu" >/dev/null 2>&1; then
	usermod -md /home/student -l student ubuntu
	groupmod -n student ubuntu
	echo "student:student" | chpasswd
	echo "root:student" | chpasswd
fi

# bashrc scripts
_copy_bashrc() {
	cp -f "/home/.bashrc" "$1"/.bashrc
	chmod 755 "$1"/.bashrc
	chown "$2:$2" "$1"/.bashrc
}
_copy_bashrc /root root
_copy_bashrc /home/student student

export DEBIAN_FRONTEND=noninteractive
# fix locale issues
locale-gen "en_US.UTF-8"
dpkg-reconfigure locales
# upgrade and install packages
apt-get update && apt-get -y upgrade
apt-get -y install rsync openssh-server curl wget bash-completion tree vim \
	neovim nano ifupdown traceroute tcpdump rsync s-nail

