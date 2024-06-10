#!/bin/bash
# Main VM provisioning entrypoint
# Everything should run as root
set -eo pipefail

export SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
chmod +x "$SRC/"*.sh

INSIDE_INSTALL_SCRIPT=1
source "$SRC/_common.sh"
wait_for_vm_boot

if [[ "$VM_NOINSTALL" == "1" ]]; then
	exit 0
fi

# run all installation tasks (in order)
while IFS=  read -r -d $'\0' file; do
	echo "> Running $(basename "$file")"
	source "$file"
done < <(find "$SRC/tasks/" '(' -type f -iname '*.sh' ')' -print0 | sort -n -z)

