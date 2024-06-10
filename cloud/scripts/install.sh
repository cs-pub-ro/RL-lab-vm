#!/bin/bash
# Install script for cloud-init
# Everything should run as root
set -e

if [[ "$VM_DEBUG" -gt 2 ]]; then
	# inspect VM only
	exit 0
fi

export SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

echo "Waiting for the VM to fully boot..."
while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] && \
	[ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do sleep 2; done

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y cloud-init cloud-utils cloud-initramfs-growroot

# delete previous cloud-init generated files
rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
rm -f /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg \
	/etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg \
	/etc/cloud/cloud.cfg.d/99-installer.cfg \
	/etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -f /etc/cloud/ds-identify.cfg
rm -f /etc/netplan/*.yaml

# enable old rsa-sha host keys (for old Guacamole versions...)
echo -e "HostkeyAlgorithms +ssh-rsa\nPubkeyAcceptedAlgorithms +ssh-rsa" > /etc/ssh/sshd_config.d/30-legacy-algs.conf

# copy our custom cloud-init config
rsync -ai --chown="root:root" "$SRC/etc/" "/etc/"

# Use old interface names (ethX) + disable qxl modeset (spice is buggy)
GRUB_CMDLINE_LINUX="quiet net.ifnames=0 biosdevname=0 nomodeset"
# disable cgroupv1 (docker might still use it... or smth')
GRUB_CMDLINE_LINUX+=" cgroup_no_v1=all"
sed -i "s/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"$GRUB_CMDLINE_LINUX\"/g" /etc/default/grub
# update grub to replace kernel cmdline
GRUB_CMDLINE_VIRT="modprobe.blacklist=floppy console=ttyS0,115200n8 no_timer_check edd=off"
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB_CMDLINE_VIRT\"/g" /etc/default/grub
update-grub

# Change root/student account passwords, if requested
if [[ -n "$RL_PASSWORD" ]]; then
	echo "root:$RL_PASSWORD" | chpasswd
	echo "student:$RL_PASSWORD" | chpasswd

	# enable ssh password-based login
	sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
	sed -i "s/.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
else
	# disable ssh password & root login
	sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config
	sed -i "s/.*PermitRootLogin.*/PermitRootLogin no/g" /etc/ssh/sshd_config
fi

# Cleanup & sysprep
apt-get -y autoremove
apt-get -y clean
rm -rf /home/student/install* /home/student/.bash_history /root/.bash_history
cloud-init clean --logs --machine-id
rm -rf /var/lib/cloud/ /tmp/*
rm -rf /var/log/*/*
rm -f /var/log/* 2>/dev/null || true

