#!/bin/bash
# Base install (requiring reboot)
# Everything should run as root
set -e

export SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

chmod +x "$SRC/"*.sh

echo "Waiting for the VM to fully boot..."
while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] && \
	[ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do sleep 2; done

if [[ "$RL_NOINSTALL" == "1" ]]; then
	exit 0
fi

# generate locales
locale-gen "en_US.UTF-8"
localectl set-locale LANG=en_US.UTF-8

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
# remove older kernels
apt-get -y --purge autoremove
# virtualization drivers & base networking
apt-get install --no-install-recommends -y open-vm-tools iproute2 ifupdown

# Change hostname to host
if [[ "$(hostname)" != "host" ]]; then
	hostnamectl set-hostname host
	sed -i "s/^127.0.1.1\s.*/127.0.1.1       host/g"  /etc/hosts
fi

# setup an empty network interfaces
mkdir -p /etc/network/
rsync -ai --chown="root:root" --chmod="755" "$SRC/files/etc/network/interfaces" /etc/network/interfaces

if grep -q " biosdevname=0 " /proc/cmdline; then
	exit 0
fi

echo "blacklist floppy" > /etc/modprobe.d/blacklist-floppy.conf
dpkg-reconfigure initramfs-tools

# Use old interface names (ethX) + disable qxl modeset (spice is buggy)
GRUB_CMDLINE_LINUX="quiet net.ifnames=0 biosdevname=0 nomodeset"
# disable cgroupv1 (docker might still use it... or smth')
GRUB_CMDLINE_LINUX+=" cgroup_no_v1=all"
sed -i "s/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX\"/g" /etc/default/grub
update-grub

# reboot
systemctl stop sshd.service
nohup shutdown -r now < /dev/null > /dev/null 2>&1 &
sleep 1
exit 0

