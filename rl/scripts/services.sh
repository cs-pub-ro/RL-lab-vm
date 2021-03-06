#!/bin/bash
set -e

echo "Installing & configuring services..." >&2
export DEBIAN_FRONTEND=noninteractive

# network services: telnetd, vsftpd
apt-get install -y telnetd vsftpd
# configs?

# apache2
apt-get install -y apache2

# postfix, courier
echo "postfix	postfix/mailname string host" | debconf-set-selections
echo "postfix	postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
apt-get install -y postfix courier-imap courier-ssl courier-imap-ssl
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
apt-get install -y isc-dhcp-server dnsmasq

