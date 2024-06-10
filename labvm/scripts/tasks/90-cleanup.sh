#!/bin/bash
# VM post-install cleanup
[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

if [[ "$VM_INSTALL_GUI" != "1" ]]; then
	apt-get -y purge libgl1-mesa-dri
fi

apt-get -y --purge autoremove
apt-get -y autoclean

if [[ "$VM_DEBUG" != "1" ]]; then
	# Cleanup the system
	rm -rf /home/student/install*
	rm -f /home/student/.bash_history
	rm -f /root/.bash_history
fi

