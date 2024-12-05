## Top-level makefile for RL Lab VM
##

FRAMEWORK_DIR ?= ./framework
include $(FRAMEWORK_DIR)/framework.mk
include $(FRAMEWORK_DIR)/lib/gen_vm_combo.mk

# set default goals
DEFAULT_GOAL = labvm
INIT_GOAL = labvm

# custom variables
NOINSTALL ?=
PACKER_ARGS_EXTRA = $(call _packer_var,vm_noinstall,$(NOINSTALL))
SUDO ?= sudo

# Fresh Ubuntu Server base VM
ubuntu-ver = 22
basevm-name = ubuntu_$(ubuntu-ver)_base
basevm-packer-src = $(FRAMEWORK_DIR)/basevm
basevm-src-image = $(BASE_VM_INSTALL_ISO)

# VM with RL lab customizations
labvm-ver = $(RL_LABVM_VERSION)
labvm-name = RL_$(labvm-ver)
labvm-packer-src = ./labvm
labvm-packer-args += -var "rl_authorized_keys=$(RL_AUTHORIZED_KEYS)"
labvm-src-from = basevm
define labvm-extra-rules=
.PHONY: labvm_compact labvm_zerofree
labvm_zerofree: labvm_compact
labvm_compact:
	$(SUDO) "$(FRAMEWORK_DIR)/utils/zerofree.sh" "$$(labvm-dest-image)"
endef

# Export to VirtualBox & VMware
localvm-name = RL_$(labvm-ver)_Local
localvm-type = vm-combo
localvm-vmname = RL $(labvm-ver) VM
localvm-src-from = labvm

# Cloud-init image
cloudvm-name = RL_$(labvm-ver)_cloud
cloudvm-packer-src = ./cloud
cloudvm-packer-args = -var "rl_admin_password=$(RL_CLOUD_ADMIN_PASSWORD)"
cloudvm-src-from = labvm
define cloudvm-extra-rules=
.PHONY: cloudvm_compact cloudvm_zerofree
cloudvm_zerofree: cloudvm_compact
cloudvm_compact:
	$(SUDO) "$(FRAMEWORK_DIR)/utils/zerofree.sh" "$$(cloudvm-dest-image)"
endef

# list with all VMs to generate rules for (note: use dependency ordering!)
build-vms += basevm labvm localvm cloudvm

$(call eval_common_rules)
$(call eval_all_vm_rules)

