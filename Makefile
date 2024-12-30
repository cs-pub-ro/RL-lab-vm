## Top-level makefile for RL Lab VM
##

# Include framework + all libraries / layers
FRAMEWORK_DIR ?= ./framework
include $(FRAMEWORK_DIR)/framework.mk
include $(FRAMEWORK_DIR)/lib/inc_all.mk

# set default goals
DEFAULT_GOAL = labvm
INIT_GOAL = labvm

# custom variables
NOINSTALL ?=
PACKER_ARGS_EXTRA = $(call _packer_var,vm_noinstall,$(NOINSTALL))
SUDO ?= sudo

# Fresh Ubuntu Server base VM
$(call vm_new_base_ubuntu,base)
base-ver = 22

labvm-ver = $(RL_LABVM_VERSION)
labvm-prefix = RL_$(labvm-ver)

# VM with RL lab customizations
$(call vm_new_layer_full_featured,labvm)
labvm-name = $(labvm-prefix)
labvm-src-from = base
# git introduces files without write access which packer cannot overwrite...
labvm-pre-copy-cmd = rm -rf thirdparty
labvm-script-prepare = rl-prepare.sh
labvm-copy-scripts += $(abspath ./labvm/scripts)/
labvm-copy-scripts += $(abspath ./thirdparty)
labvm-extra-rules += $(vm_zerofree_rule)

# Export to VirtualBox & VMware
localvm-name = $(labvm-prefix)_Local
localvm-type = vm-combo
localvm-vmname = RL $(labvm-ver) VM
localvm-src-from = labvm
localvm-extra-rules += $(vm_zerofree_rule)

# Cloud-init image
cloudvm-name = $(labvm-prefix)_cloud
cloudvm-packer-src = ./cloud
cloudvm-packer-args = -var "rl_admin_password=$(RL_CLOUD_ADMIN_PASSWORD)"
cloudvm-src-from = labvm
cloudvm-extra-rules += $(vm_zerofree_rule)

# list with all VMs to generate rules for (note: use dependency ordering!)
build-vms = base labvm localvm cloudvm

$(call vm_eval_all_rules)
