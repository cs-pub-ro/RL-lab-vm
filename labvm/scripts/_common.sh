#!/bin/bash
# Common installer functions for the host and containers

# Some tweaks
function tweak_ubuntu() {
	sed -i 's/^ENABLED.*/ENABLED=0/' /etc/default/motd-news
	sed -i 's/^UseDNS.*/UseDNS yes/' /etc/ssh/sshd_config

	# we prefer ipv4, thanks
	GAI_PREFER_IPV4="precedence ::ffff:0:0/96  100"
	gai_file="/etc/gai.conf"
	if ! grep "^$GAI_PREFER_IPV4" "$gai_file"; then
		echo "$GAI_PREFER_IPV4" >> "$gai_file"
	fi
}

