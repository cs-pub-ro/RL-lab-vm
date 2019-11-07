# Makefile for building the images

# user variables
TMP_DIR = /tmp/packer
OS_INSTALL_ISO = REQUIRED

PACKER = packer
PACKER_ARGS = -on-error=abort
TRANSFORMER = ./build-scripts/packer_transform.py

BASE_VM_NAME = Ubuntu_18_base
BASE_PACKER_CONFIG = base/ubuntu_18.yaml
BASE_VM_IMAGE = $(TMP_DIR)/$(BASE_VM_NAME)/$(BASE_VM_NAME).qcow2

RL_VM_NAME = RL_2019
RL_PACKER_CONFIG = rl/rl.yaml
RL_VM_IMAGE = $(TMP_DIR)/$(RL_VM_NAME)/$(RL_VM_NAME).qcow2

# include local customizations file
include local.mk

base: $(RL_VM_IMAGE)

$(BASE_VM_IMAGE): VM_DIR=$(TMP_DIR)/$(BASE_VM_NAME)
$(BASE_VM_IMAGE): $(TMP_DIR)/
	$(if $(DELETE),rm -rf "$(VM_DIR)/",)
	cat "$(BASE_PACKER_CONFIG)" | $(TRANSFORMER) | \
		env "PACKER_TMP_DIR=$(TMP_DIR)" "PACKER_CACHE_DIR=$(TMP_DIR)/packer_cache/" \
		"TMPDIR=$(TMP_DIR)" "VM_NAME=$(BASE_VM_NAME)" "OUTPUT_DIR=$(VM_DIR)" \
		"OS_INSTALL_ISO=$(OS_INSTALL_ISO)" \
		$(PACKER) build $(PACKER_ARGS) -only=qemu -

rl_vm: VM_DIR=$(TMP_DIR)/$(RL_VM_NAME)
rl_vm: $(TMP_DIR)/
	$(if $(DELETE),rm -rf "$(VM_DIR)/",)
	cat "$(RL_PACKER_CONFIG)" | $(TRANSFORMER) | \
		env "PACKER_TMP_DIR=$(TMP_DIR)" "PACKER_CACHE_DIR=$(TMP_DIR)/packer_cache/" \
		"TMPDIR=$(TMP_DIR)" "VM_NAME=$(RL_VM_NAME)" "OUTPUT_DIR=$(VM_DIR)" \
		"BASE_VM=$(BASE_VM_IMAGE)" \
		$(PACKER) build $(PACKER_ARGS) -only=qemu -

validate:
	cat "$(BASE_PACKER_CONFIG)" | $(TRANSFORMER) | $(PACKER) validate -
	cat "$(RL_PACKER_CONFIG)" | $(TRANSFORMER) | $(PACKER) validate -

$(TMP_DIR)/:
	mkdir -p $(TMP_DIR)/

print-%  : ; @echo $* = $($*)

.PHONY: base validate

