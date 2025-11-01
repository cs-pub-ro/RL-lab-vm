#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }

rsync -rvh --chown=root --chmod=755 "$RL_SRC/rl_files/opt/rl/" /opt/rl/

# copy the lab scripts (separate repo for upgradibility)
LABS_SRC="$RL_SRC/thirdparty/labs"
LABS_DEST="/opt/rl-labs"
if [[ ! -f "$LABS_SRC" ]]; then
	rm -rf "$LABS_DEST"
	rsync -a --chown=root:root --mkpath "$LABS_SRC/" "$LABS_DEST/"
else
	echo "Warning: missing '$LABS_SRC'!" \
		"Lab scripts will NOT be present in this image..." >&2
fi

# build rl-labs
(
	set -e
	cd "$LABS_DEST"
	./build.sh
)

# Install rl-watchdog service
vm_run_script "$RL_SRC/rl_files/opt/rl/watchdog/install.sh"

