#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }

# Install rl-watchdog service
vm_run_script "$RL_SRC/rl_files/opt/rl/watchdog/install.sh"

# Install ContainerNet + lab scripts inside the VM
# TODO: move from ansible to simple bash script
rsync -rvh --chown=root --chmod=755 "$RL_SRC/rl_files/opt/rl/" /opt/rl/
export RL_SRC
bash "$RL_SRC/ansible/provision.sh"

