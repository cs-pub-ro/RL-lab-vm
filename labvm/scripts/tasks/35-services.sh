#!/bin/bash
# VM Services install / configuration script
[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

echo "Installing & configuring services..." >&2

# Use Systemd presets to disable services by default
SYSTEMD_PRESET_FILE=/etc/systemd/system-preset/90-default-servers.preset
mkdir -p /etc/systemd/system-preset/

# network services: telnetd, vsftpd
rsync -rvh --chown=root --chmod=755 "$SRC/files/etc/vsftpd.conf" /etc
apt-get install --no-install-recommends -y telnetd vsftpd

# apache2
apt-get install --no-install-recommends -y apache2 libapache2-mod-php

# postfix, courier
echo "postfix postfix/mailname string host" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
apt-get install --no-install-recommends -y postfix courier-imap
# configure mail
postconf -e 'home_mailbox= Maildir/'
# use maildir for reading mail
if ! grep "^export MAIL=" /etc/bash.bashrc; then
	echo 'export MAIL=~/Maildir' >> /etc/bash.bashrc
fi
if ! grep "^export MAIL=" /etc/bash.bashrc; then
	echo 'export MAIL=~/Maildir' >> /etc/profile.d/mail.sh
	chmod +x /etc/profile.d/mail.sh
fi

# DHCP servers
echo "disable dnsmasq.service" > "$SYSTEMD_PRESET_FILE"
echo "disable isc-dhcp-server.service" > "$SYSTEMD_PRESET_FILE"
echo "disable isc-dhcp-server6.service" >> "$SYSTEMD_PRESET_FILE"
apt-get install --no-install-recommends -y isc-dhcp-server dnsmasq
systemctl disable dnsmasq
systemctl disable isc-dhcp-server
systemctl disable isc-dhcp-server6.service

