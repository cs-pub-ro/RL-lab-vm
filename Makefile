# Makefile for building the images

# user variables (override in local.mk)
TMP_DIR =
OS_INSTALL_ISO = 
DEBUG = 0
PAUSE = $(DEBUG)
DELETE = 
PACKER = packer
PACKER_ARGS = -on-error=abort \
			  -var "vm_pause=$(PAUSE)" -var "vm_debug=$(DEBUG)"
SSH = ssh
SSH_ARGS = 

# Fresh Ubuntu Server XX.04 base install
BASE_VM_NAME = Ubuntu_22_base
BASE_VM_SRC = base/
BASE_VM_OUT_DIR = $(TMP_DIR)/$(BASE_VM_NAME)
BASE_VM_OUT_IMAGE = $(BASE_VM_OUT_DIR)/$(BASE_VM_NAME).qcow2

# main lab VM image (from BASE)
LAB_VM_NAME = RL_2022
LAB_VM_SRC = rl/
LAB_VM_OUT_DIR = $(TMP_DIR)/$(LAB_VM_NAME)
LAB_VM_OUT_IMAGE = $(LAB_VM_OUT_DIR)/$(LAB_VM_NAME).qcow2

# cloud-targeted image (from on LABVM)
CLOUD_VM_NAME = RL_2022_cloud
CLOUD_VM_SRC = rl-cloud/
CLOUD_VM_OUT_DIR = $(TMP_DIR)/$(CLOUD_VM_NAME)
CLOUD_VM_OUT_IMAGE = $(CLOUD_VM_OUT_DIR)/$(CLOUD_VM_NAME).qcow2

# include local customizations file
include local.mk

# macro for packer build script generation
# args:
_VM_SRC = $(strip $(1))
_VM_NAME = $(strip $(2))
_VM_SOURCE_IMAGE = $(strip $(3))
_VM_OUT_DIR = $(TMP_DIR)/$(_VM_NAME)
_PACKER_ARGS = $(PACKER_ARGS) \
			 -var "vm_name=$(_VM_NAME).qcow2" \
			 -var "source_image=$(_VM_SOURCE_IMAGE)" \
			 -var "output_directory=$(_VM_OUT_DIR)"
define packer_gen_build
	$(if $(DELETE),rm -rf "$(_VM_OUT_DIR)/",)
	cd "$(_VM_SRC)" && $(PACKER) build $(_PACKER_ARGS) "./"
endef

# Base image
base: $(BASE_VM_OUT_IMAGE)
$(BASE_VM_OUT_IMAGE): $(wildcard $(BASE_VM_SRC)/**) | $(TMP_DIR)/.empty
	$(call packer_gen_build, $(BASE_VM_SRC), \
		$(BASE_VM_NAME), $(OS_INSTALL_ISO))
base_clean:
	rm -rf "$(dir $(BASE_VM_OUT_IMAGE))/"

# RL scripts VM
labvm: $(LAB_VM_OUT_IMAGE)
$(LAB_VM_OUT_IMAGE): $(wildcard $(LAB_VM_SRC)/**) | $(BASE_VM_OUT_IMAGE)
	$(call packer_gen_build, $(LAB_VM_SRC), \
		$(LAB_VM_NAME), $(BASE_VM_OUT_IMAGE))

labvm_clean:
	rm -rf "$(dir $(LAB_VM_OUT_IMAGE))/"

# Quickly edit an already-generated Lab VM image
labvm_edit: PAUSE=1
labvm_edit: | $(LAB_VM_OUT_IMAGE)
	$(call packer_gen_build, $(LAB_VM_SRC), \
		$(LAB_VM_NAME)_tmp, $(LAB_VM_OUT_IMAGE))
labvm_edit_clean:
	rm -rf "$(LAB_VM_OUT_DIR)_tmp/"
# commits the edited image back to the original
LAB_VM_TMP_OUT_IMAGE = $(LAB_VM_OUT_DIR)_tmp/$(LAB_VM_NAME)_tmp.qcow2
labvm_commit:
	qemu-img commit "$(LAB_VM_TMP_OUT_IMAGE)"
	rm -rf "$(LAB_VM_OUT_DIR)_tmp/"

QEMU_NBD_DEV=nbd0
labvm_zerofree:
	sudo qemu-nbd -c "/dev/$(QEMU_NBD_DEV)" "$(LAB_VM_OUT_IMAGE)"
	sudo zerofree "/dev/$(QEMU_NBD_DEV)p1"
	sudo qemu-nbd -d "/dev/$(QEMU_NBD_DEV)"

labvmdk:
	qemu-img convert -O vmdk "$(LAB_VM_OUT_IMAGE)" "$(LAB_VM_OUT_DIR)/$(LAB_VM_NAME).vmdk"

# ssh into a packer/qemu VM (note: only labvm-derived images support this)
ssh:
	$(SSH) $(SSH_ARGS) student@127.0.0.1 -p 20022

.PHONY: base labvm labvm_edit labvm_commit ssh

# Lab VM cloud-init variant (for EC2 / OpenStack)
cloudvm: $(CLOUD_VM_OUT_IMAGE)
$(CLOUD_VM_OUT_IMAGE): $(wildcard $(CLOUD_VM_SRC)/**) | $(LAB_VM_OUT_IMAGE)
	$(call packer_gen_build, $(CLOUD_VM_SRC), \
		$(CLOUD_VM_NAME), $(LAB_VM_OUT_IMAGE))
	qemu-img convert -O qcow2 "$(CLOUD_VM_OUT_IMAGE)" "$(CLOUD_VM_OUT_DIR)/$(CLOUD_VM_NAME)_big.qcow2"

# VM backing an already generated RL scripts image (saving time to edit it)
cloudvm_edit: | $(CLOUD_VM_OUT_IMAGE)
	$(call packer_gen_build, $(CLOUD_VM_SRC), \
		$(CLOUD_VM_NAME)_tmp, $(CLOUD_VM_OUT_IMAGE))

cloudvm_clean:
	rm -rf "$(TMP_DIR)/$(CLOUD_VM_NAME)/"

.PHONY: cloudvm cloudvm_edit cloudvm_clean

$(TMP_DIR)/.empty:
	mkdir -p "$(TMP_DIR)/"
	touch "$(TMP_DIR)/.empty"

print-%  : ; @echo $* = $($*)

