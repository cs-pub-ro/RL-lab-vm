#!/bin/bash
set -e
set -x

# Root password
echo 'root:student' | chpasswd

# Disable UFW
systemctl disable ufw

# Change hostname to host
hostnamectl set-hostname host
sed -i "s/^127.0.1.1\s.*/127.0.1.1       host/g"  /etc/hosts

# Copy configs
rsync -avh --chown="root:root" "$SRC/files/etc/" /etc/
rsync -avh --chown="root:root" "$SRC/files/opt/" /opt/
chmod 755 /etc/rc.local
chmod 755 /etc/network/interfaces

# bashrc
_copy_bashrc() {
	cp -f "$SRC/files/home/bashrc" "$1"/.bashrc
	chmod 755 "$1"/.bashrc
	chown "$2:$2" "$1"/.bashrc
}
_copy_bashrc /root root
_copy_bashrc /home/student student

# Use old interface names (ethX)
sed -i "s/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"/g" /etc/default/grub
update-grub

