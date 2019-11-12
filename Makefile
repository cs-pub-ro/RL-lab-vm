# Makefile for building the images

# user variables
TMP_DIR = /tmp/packer
OS_INSTALL_ISO = REQUIRED

PACKER = packer
PACKER_ARGS = -on-error=abort
TRANSFORMER = ./build-scripts/packer_transform.py
SSH = ssh
SSH_ARGS = 

# Fresh Ubuntu 18.04 base install
BASE_VM_NAME = Ubuntu_18_base
BASE_PACKER_CONFIG = base/ubuntu_18.yaml
BASE_VM_IMAGE = $(TMP_DIR)/$(BASE_VM_NAME)/$(BASE_VM_NAME).qcow2

# main RL scripts image (from BASE)
RL_SCRIPTS_VM_NAME = RL_2019
RL_SCRIPTS_PACKER_CONFIG = rl/rl.yaml
RL_SCRIPTS_VM_IMAGE = $(TMP_DIR)/$(RL_SCRIPTS_VM_NAME)/$(RL_SCRIPTS_VM_NAME).qcow2

# cloud (EC2 / OpenStack) image (from on RL_SCRIPTS)
RL_CLOUD_VM_NAME = RL_2019_cloud
RL_CLOUD_PACKER_CONFIG = rl-cloud/rl-cloud.yaml
RL_CLOUD_VM_IMAGE = $(TMP_DIR)/$(RL_CLOUD_NAME)/$(RL_CLOUD_NAME).qcow2

# include local customizations file
include local.mk

# macro for packer build script generation
# args:
_VM_TEMPLATE = $(strip $(1))
_VM_NAME = $(strip $(2))
_VM_SOURCE = $(strip $(3))
_VM_DIR = $(TMP_DIR)/$(_VM_NAME)
_TRANSFORM_ARGS=
define packer_gen_build
	$(if $(DELETE),rm -rf "$(_VM_DIR)/",)
	cat "$(_VM_TEMPLATE)" | $(TRANSFORMER) $(_TRANSFORM_ARGS) | \
		env "PACKER_TMP_DIR=$(TMP_DIR)" "PACKER_CACHE_DIR=$(TMP_DIR)/packer_cache/" \
		"TMPDIR=$(TMP_DIR)" "VM_NAME=$(_VM_NAME)" "OUTPUT_DIR=$(_VM_DIR)" \
		"SOURCE_IMAGE=$(_VM_SOURCE)" \
		$(PACKER) build $(PACKER_ARGS) -only=qemu -
endef

# Base image
base: $(BASE_VM_IMAGE)
$(BASE_VM_IMAGE): | $(TMP_DIR)/
	$(call packer_gen_build, $(BASE_PACKER_CONFIG), \
		$(BASE_VM_NAME), $(OS_INSTALL_ISO))

# RL scripts VM
rl_scripts: $(RL_SCRIPTS_VM_IMAGE)
$(RL_SCRIPTS_VM_IMAGE): $(BASE_VM_IMAGE)
	$(call packer_gen_build, $(RL_SCRIPTS_PACKER_CONFIG), \
		$(RL_SCRIPTS_VM_NAME), $(BASE_VM_IMAGE))

# VM backing an already generated RL scripts image (saving time to edit it)
rl_scripts_edit: _TRANSFORM_ARGS=--add-breakpoint
rl_scripts_edit: $(RL_SCRIPTS_VM_IMAGE)
	$(call packer_gen_build, $(RL_SCRIPTS_PACKER_CONFIG), \
		$(RL_SCRIPTS_VM_NAME)_tmp, $(RL_SCRIPTS_VM_IMAGE))
# commits the edited image back to the original
RL_SCRIPTS_TMP_IMAGE = $(TMP_DIR)/$(RL_SCRIPTS_VM_NAME)_tmp/$(RL_SCRIPTS_VM_NAME)_tmp.qcow2
rl_scripts_commit:
	qemu-img commit "$(RL_SCRIPTS_TMP_IMAGE)"

# ssh into a packer-opened VM (note: only rl_* support this)
rl_ssh:
	$(SSH) $(SSH_ARGS) student@127.0.0.1 -p 20022

.PHONY: base rl_scripts rl_scripts_edit rl_scripts_commit rl_ssh

# RL cloud image (EC2 / OpenStack)
rl_cloud: $(RL_CLOUD_VM_IMAGE)
$(RL_CLOUD_VM_IMAGE): $(RL_SCRIPTS_VM_IMAGE)
	$(call packer_gen_build, $(RL_CLOUD_PACKER_CONFIG), \
		$(RL_CLOUD_VM_NAME), $(RL_SCRIPTS_VM_IMAGE))

rl_cloud_test: _TRANSFORM_ARGS=--add-breakpoint
rl_cloud_test: $(RL_CLOUD_VM_IMAGE)
	$(call packer_gen_build, $(RL_CLOUD_PACKER_CONFIG), \
		$(RL_CLOUD_VM_NAME)_test, $(RL_SCRIPTS_VM_IMAGE))

.PHONY: rl_cloud rl_cloud_test

validate:
	cat "$(BASE_PACKER_CONFIG)" | $(TRANSFORMER) | $(PACKER) validate -
	cat "$(RL_SCRIPTS_PACKER_CONFIG)" | $(TRANSFORMER) | $(PACKER) validate -
	cat "$(RL_CLOUD_PACKER_CONFIG)" | $(TRANSFORMER) | $(PACKER) validate -
.PHONY: validate

$(TMP_DIR)/:
	mkdir -p $(TMP_DIR)/

print-%  : ; @echo $* = $($*)


