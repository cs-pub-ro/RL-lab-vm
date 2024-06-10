#!/bin/bash
# VM install initialization
[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

# install prerequisites
echo "Installing base packages (prerequisites)..." >&2

# configure DPKG to keep our config files
cat << EOF > /etc/apt/apt.conf.d/30keep-provisioned-configs
Dpkg::Options {
	"--force-confdef";
	"--force-confold";
}
EOF

apt-get install --no-install-recommends -y \
	apt-transport-https software-properties-common ca-certificates gnupg \
	curl wget git unrar unzip zsh vim

if [[ -n "$FULL_UPGRADE" ]]; then
	apt-get dist-upgrade -y
fi

