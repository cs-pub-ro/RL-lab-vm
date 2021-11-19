#!/bin/bash
# Main RL VM provisioning entrypoint
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

source "$SRC/_common.sh"
. "$SRC/packages.sh"
. "$SRC/services.sh"
. "$SRC/tweaks.sh"

# use ansible for the rest of the provisioning process
. "$SRC/ansible/provision.sh"

if [[ "$RL_DEBUG" != "1" ]]; then
	# Cleanup the system
	apt-get -y purge libgl1-mesa-dri
	apt-get -y --purge autoremove
	apt-get -y autoclean
	rm -rf /home/student/install*
	rm -f /home/student/.bash_history
	rm -f /root/.bash_history
fi

