#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Docker + container utils installation

# MTU fix for OpenStack VMs
cat << EOF > /etc/docker/daemon.json
{
  "mtu": 1450,
  "features": {"buildkit": true}
}
EOF

# dunno why these are wrong...
mkdir -p /home/student/.docker
chown student:student -R /home/student/.docker
chmod 755 -R /home/student/.docker

