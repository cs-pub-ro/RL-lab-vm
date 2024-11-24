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
rm -f /etc/cloud/cloud-init.disabled
rm -f /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg \
	/etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg \
	/etc/cloud/cloud.cfg.d/99-installer.cfg \
	/etc/cloud/cloud.cfg.d/99-installer.cfg \
	/etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -f /etc/cloud/ds-identify.cfg
rm -f /etc/netplan/*.yaml

# enable old rsa-sha host keys (for old Guacamole versions...)
echo -e "HostkeyAlgorithms +ssh-rsa\nPubkeyAcceptedAlgorithms +ssh-rsa" > /etc/ssh/sshd_config.d/30-legacy-algs.conf

# copy our custom cloud-init config
rsync -ai --chown="root:root" "$SRC/etc/" "/etc/"

# update grub to replace kernel cmdline
GRUB_CMDLINE_VIRT="modprobe.blacklist=floppy console=ttyS0,115200n8 no_timer_check edd=off"
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB_CMDLINE_VIRT\"/g" /etc/default/grub
update-grub

# disable ssh password & root login
sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/.*PermitRootLogin.*/PermitRootLogin no/g" /etc/ssh/sshd_config

# Set admin credentials
if [[ -n "$RL_ADMIN_PASSWORD" ]]; then
	echo "admin:$RL_ADMIN_PASSWORD" | chpasswd
	# enable password auth for 'admin'
	cat <<EOF >"/etc/ssh/sshd_config.d/20-admin-auth.conf"
Match User "admin"
	PasswordAuthentication yes
EOF
else
	rm -f "/etc/ssh/sshd_config.d/20-admin-auth.conf"
fi

# cloud-init boot hack
sed -i '/Before=sysinit.target/d' /usr/lib/systemd/system/cloud-init.service
sed -i '/Before=network-online.target/d' /usr/lib/systemd/system/cloud-init.service
systemctl disable systemd-networkd
systemctl disable systemd-networkd-wait-online
systemctl disable isc-dhcp-server6.service
systemctl enable docker.service
systemctl daemon-reload

# Cleanup & sysprep
apt-get -y autoremove
apt-get -y clean
rm -rf /home/student/install* /home/student/.bash_history /root/.bash_history
cloud-init clean --logs --machine-id
rm -rf /var/lib/cloud/ /tmp/*
rm -rf /var/log/*/*
rm -f /var/log/* 2>/dev/null || true

