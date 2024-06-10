#!/bin/bash
# VM install initialization

[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

# prevent prompts from `apt`
export DEBIAN_FRONTEND=noninteractive

# uncomment to skip costly installation steps
VM_INSTALL_GUI=${VM_INSTALL_GUI:-0}

# update the repos
apt-get update

