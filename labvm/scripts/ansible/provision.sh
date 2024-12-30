#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# set python3 as default
update-alternatives --install /usr/bin/python python /usr/bin/python3 10

# install ansible
sudo apt-add-repository --yes --update ppa:ansible/ansible-7
sudo apt-get update
sudo apt-get install -y ansible

pip3 uninstall -y requests
pip3 install 'requests<2.32.0' 'docker<7.0.0'

# install community modules
ansible-galaxy collection install community.general
ansible-galaxy install kwoodson.yedit

# copy the lab scripts
LABS_SRC="$RL_SRC/thirdparty/labs"
LABS_DEST="/opt/rl-labs"
if [[ ! -f "$LABS_SRC" ]]; then
	rm -rf "$LABS_DEST"
	rsync -a --chown=root:root --mkpath "$LABS_SRC/" "$LABS_DEST/"
else
	echo "Warning: missing '$LABS_SRC'!" \
		"Lab scripts will NOT be present in this image..." >&2
fi

# run the ansible playbook to install / configure the lab environment
(
	export LABS_DEST
	cd "$RL_SRC/ansible"
	ansible-playbook -i inventory -c local install.yml
)

