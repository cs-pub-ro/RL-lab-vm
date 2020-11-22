# Makefile for building the images

# user variables
TMP_DIR = /tmp/packer
OS_INSTALL_ISO = REQUIRED

PACKER = packer
PACKER_ARGS = -on-error=abort -var "rl_debug=$(DEBUG)"
TRANSFORMER = ./build-scripts/packer_transform.py
SSH = ssh
SSH_ARGS = 
DEBUG =  # set to 1 to keep the files at the end of the operation
PAUSE = $(DEBUG)

# Fresh Ubuntu 18.04 base install
BASE_VM_NAME = Ubuntu_18_base
BASE_PACKER_CONFIG = base/ubuntu_18.yaml
BASE_VM_IMAGE = $(TMP_DIR)/$(BASE_VM_NAME)/$(BASE_VM_NAME).qcow2
BASE_VM_IMAGE_GUARD = $(TMP_DIR)/$(BASE_VM_NAME)/.generated

# main lab VM image (from BASE)
LABVM_NAME = RL_2020
LABVM_PACKER_CONFIG = rl/rl.yaml
LABVM_IMAGE = $(TMP_DIR)/$(LABVM_NAME)/$(LABVM_NAME).qcow2

# cloud-targeted image (from on LABVM)
CLOUDVM_NAME = RL_2020_cloud
CLOUDVM_PACKER_CONFIG = rl-cloud/rl-cloud.yaml
CLOUDVM_IMAGE = $(TMP_DIR)/$(CLOUDVM_NAME)/$(CLOUDVM_NAME).qcow2

# include local customizations file
include local.mk

# macro for packer build script generation
# args:
_VM_TEMPLATE = $(strip $(1))
_VM_NAME = $(strip $(2))
_VM_SOURCE = $(strip $(3))
_VM_DIR = $(TMP_DIR)/$(_VM_NAME)
_TRANSFORM_ARGS=$(if $(PAUSE),--add-breakpoint,)
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
$(BASE_VM_IMAGE): $(BASE_VM_IMAGE_GUARD)
$(BASE_VM_IMAGE_GUARD): | $(TMP_DIR)/.empty
	$(call packer_gen_build, $(BASE_PACKER_CONFIG), \
		$(BASE_VM_NAME), $(OS_INSTALL_ISO))
	touch "$(BASE_VM_IMAGE_GUARD)"

# RL scripts VM
labvm: $(LABVM_IMAGE)
$(LABVM_IMAGE): | $(BASE_VM_IMAGE)
	$(call packer_gen_build, $(LABVM_PACKER_CONFIG), \
		$(LABVM_NAME), $(BASE_VM_IMAGE))

labvm_clean:
	rm -rf "$(TMP_DIR)/$(LABVM_NAME)/"

# VM backing an already generated RL scripts image (saving time to edit it)
labvm_edit: | $(LABVM_IMAGE)
	$(call packer_gen_build, $(LABVM_PACKER_CONFIG), \
		$(LABVM_NAME)_tmp, $(LABVM_IMAGE))
# commits the edited image back to the original
LABVM_TMP_IMAGE = $(TMP_DIR)/$(LABVM_NAME)_tmp/$(LABVM_NAME)_tmp.qcow2
labvm_commit:
	qemu-img commit "$(LABVM_TMP_IMAGE)"
	rm -rf "$(TMP_DIR)/$(LABVM_NAME)_tmp/"

# ssh into a packer/qemu VM (note: only labvm-derived images support this)
ssh:
	$(SSH) $(SSH_ARGS) student@127.0.0.1 -p 20022

.PHONY: base labvm labvm_edit labvm_commit ssh

# RL cloud image (EC2 / OpenStack)
cloudvm: $(CLOUDVM_IMAGE)
$(CLOUDVM_IMAGE): $(LABVM_IMAGE)
	$(call packer_gen_build, $(CLOUDVM_PACKER_CONFIG), \
		$(CLOUDVM_NAME), $(LABVM_IMAGE))
	qemu-img convert -O qcow2 "$(LABVM_IMAGE)" "$(TMP_DIR)/$(CLOUDVM_NAME)/$(CLOUDVM_NAME)_big.qcow2"

.PHONY: cloudvm

validate:
	cat "$(BASE_PACKER_CONFIG)" | $(TRANSFORMER) | $(PACKER) validate -
	cat "$(LABVM_PACKER_CONFIG)" | $(TRANSFORMER) | $(PACKER) validate -
	cat "$(CLOUDVM_PACKER_CONFIG)" | $(TRANSFORMER) | $(PACKER) validate -
.PHONY: validate

$(TMP_DIR)/.empty:
	mkdir -p "$(TMP_DIR)/"
	touch "$(TMP_DIR)/.empty"

print-%  : ; @echo $* = $($*)

