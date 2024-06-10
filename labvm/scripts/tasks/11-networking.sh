#!/bin/bash
# VM network configuration
[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

apt-get install --no-install-recommends -y iproute2 ifupdown-ng bridge-utils

rsync -rvh --chown=root --chmod=755 "$SRC/files/etc/network/" /etc/network/
rsync -rvh --chown=root --chmod=755 "$SRC/files/etc/rc.local" /etc/

