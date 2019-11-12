# Local build variables
# Copy this as 'local.mk'

# Path to required ISO images
OS_INSTALL_ISO = $(HOME)/Downloads/ubuntu-18.04.3-server-amd64.iso
VMWARE_ISO = $(HOME)/Downloads/VMware-Tools-core-10.3.2-9925305.zip

# Temporary and output directory to use.
# Make sure you have >10GB free space!
TMP_DIR=/tmp/packer

# SSH args (prevent host key warnings)
SSH_ARGS=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

