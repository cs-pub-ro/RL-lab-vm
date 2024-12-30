#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# RL Lab VM preparation script
# Cherry picks provisioning snippets to obtain the desired configuration.

# run the full preparation script to symlink the appropriate stages
vm_run_script "full-prepare.sh"

