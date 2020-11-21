#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# set python3 as default
update-alternatives --install /usr/bin/python python /usr/bin/python3 10

# install ansible
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible

# install community modules
ansible-galaxy collection install community.general

# copy + run ansible installation
CONTAINERLAB_SRC="$SRC/thirdparty/containerlab"
if [[ ! -f "$CONTAINERLAB_SRC" ]]; then
	export CONTAINERLAB_INSTALL="/tmp/containerlab"
	rm -rf /tmp/containerlab
	cp -ar "$CONTAINERLAB_SRC/" "$CONTAINERLAB_INSTALL/"
	cd "$CONTAINERLAB_INSTALL/ansible" && ansible-playbook -i inventory -c local install.yml

else
	echo "Warning: missing '$CONTAINERLAB_SRC'!" \
		"Containers will NOT be configured in this image..." >/dev/stderr
fi

