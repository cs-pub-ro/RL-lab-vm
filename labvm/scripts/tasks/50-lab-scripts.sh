#!/bin/bash
# Install ContainerNet + lab scripts inside the VM
# TODO: move from ansible to simple bash script

rsync -rvh --chown=root --chmod=755 "$SRC/files/opt/rl/" /opt/rl/

bash "$SRC/ansible/provision.sh"

