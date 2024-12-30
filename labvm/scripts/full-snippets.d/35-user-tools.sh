#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# Install user tools

# terminal utilities: covered by fully_featured
pkg_install --no-install-recommends tmux vim-nox nano bash-completion less \
	pciutils usbutils lshw sysstat

# python / dev libraries
pkg_install --no-install-recommends \
	python3 python3-venv python3-pip python3-setuptools libssl-dev libffi-dev

# Install a newer neovim (from unstable ppa)
add-apt-repository -y ppa:neovim-ppa/unstable
pkg_init_update
pkg_install neovim

