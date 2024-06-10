#!/bin/bash
# VM system tweaks
[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

# remove MOTD snippets, disable SSH dns lookup
sed -i 's/^ENABLED.*/ENABLED=0/' /etc/default/motd-news
sed -i 's/^UseDNS.*/UseDNS no/' /etc/ssh/sshd_config

#ls -lh /etc/update-motd.d/
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news
chmod -x /etc/update-motd.d/91-release-upgrade
chmod -x /etc/update-motd.d/92-unattended-upgrades

# tell GAI that we prefer ipv4, thanks
GAI_PREFER_IPV4="precedence ::ffff:0:0/96  100"
gai_file="/etc/gai.conf"
if ! grep "^$GAI_PREFER_IPV4" "$gai_file"; then
	echo "$GAI_PREFER_IPV4" >> "$gai_file"
fi

# disable password authentication (enabled by cloud-init :/ )
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf

