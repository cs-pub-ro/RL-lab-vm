#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Admin user provisioning
# Used by cloud admins ;) 

@import 'linux'

# create the admin user
sh_create_user admin 1966

usermod -aG "docker,sudo" admin
echo 'admin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/admin

# Note: this will be changed in private cloud VMs
echo "admin:admin1337" | chpasswd

