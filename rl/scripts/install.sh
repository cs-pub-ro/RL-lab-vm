#!/bin/bash
# Main RL VM provisioning entrypoint

export SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

chmod +x "$SRC/"*.sh

"$SRC/packages.sh"
"$SRC/tweaks.sh"
"$SRC/lxc.sh"

