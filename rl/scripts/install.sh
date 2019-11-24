#!/bin/bash
# Main RL VM provisioning entrypoint
# Everything should run as root
set -e

export SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

chmod +x "$SRC/"*.sh

echo "Waiting for the VM to fully boot..."
while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] && \
	[ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do sleep 2; done

"$SRC/packages.sh"
"$SRC/tweaks.sh"
"$SRC/lxc.sh"
"$SRC/services.sh"

if [[ "$RL_DEBUG" != "1" ]]; then
	# Cleanup the system
	rm -rf /home/student/install*
	rm -f /home/student/.bash_history
	rm -f /root/.bash_history
fi

