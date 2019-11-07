#!/bin/sh
# Base provisioning script

apt-get install -y wget curl

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

if grep "^UseDNS yes" /etc/ssh/sshd_config; then
	sed "s/^UseDNS yes/UseDNS no/" /etc/ssh/sshd_config > /tmp/sshd_config
	mv /tmp/sshd_config /etc/ssh/sshd_config
else
	echo "UseDNS no" >> /etc/ssh/sshd_config
fi

