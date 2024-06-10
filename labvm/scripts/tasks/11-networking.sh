#!/bin/bash
# VM network configuration
[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

apt-get install --no-install-recommends -y iproute2 ifupdown-ng bridge-utils

rsync -rvh --chown=root --chmod=755 "$SRC/files/etc/network/" /etc/network/
rsync -rvh --chown=root --chmod=755 "$SRC/files/etc/rc.local" /etc/

# cloud-init systemd dependency cycle workaround
sed -i '/Before=sysinit.target/d' /usr/lib/systemd/system/cloud-init.service
systemctl daemon-reload

# disable cloud-init
touch /etc/cloud/cloud-init.disabled

# disable systemd-networkd please
systemctl disable systemd-networkd.service
systemctl mask systemd-networkd.service
systemctl disable systemd-networkd-wait-online.service
systemctl mask systemd-networkd-wait-online.service

