#!/bin/bash
set -e

# Root password
echo 'root:student' | chpasswd

# Disable UFW
systemctl disable ufw

# Example rc.local
cp "$SRC/files/rc.local" /etc/rc.local
chmod 755 /etc/rc.local

