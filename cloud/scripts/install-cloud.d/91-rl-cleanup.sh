#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Cleanup RL install scripts + history

rm -rf /opt/vm-scripts/install-*
rm -rf /opt/vm-scripts/full-*
rm -rf /home/student/.bash_history /root/.bash_history

