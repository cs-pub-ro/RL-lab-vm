#!/bin/bash
# Tweaks for the host
set -e

# disable MOTD news, disable ssh DNS
tweak_ubuntu

# Copy configs
rsync -ai --chown="root:root" "$SRC/files/etc/" /etc/
rsync -ai --chown="root:root" "$SRC/files/opt/" /opt/
chmod 755 /etc/rc.local
chmod 755 /etc/network/interfaces

# user home configs
_copy_home_config() {
	# copy & enable bashrc:
	cp -f "$SRC/files/home/bashrc" "$1"/.bashrc
	chmod 755 "$1"/.bashrc
	chown "$2:$2" "$1"/.bashrc
	# copy tmux config
	mkdir -p "$1"/.config/tmux/
	rsync -ai --chown="$2:$2" "$SRC/files/home/tmux/" "$1/.config/tmux/"
	ln -sf "$1/.config/tmux/tmux.conf" "$1/.tmux.conf"
	chown "$2:$2" "$1/.tmux.conf"
}
_copy_home_config /root root
_copy_home_config /home/student student

