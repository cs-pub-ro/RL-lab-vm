#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
# rl-watchdog service installation script
# Should be run using vm-scripts!

@import "systemd"
_SRC=$(sh_get_script_path)

install -m755 -d /opt/rl/watchdog/
install -m755 "$_SRC/rl-watchdog.sh" /opt/rl/watchdog/rl-watchdog.sh

if ! systemd_is_enabled rl-watchdog; then
	systemd_install_service "$_SRC/rl-watchdog.service" rl-watchdog
	systemctl -q restart rl-watchdog
	echo "Safety rl-watchdog service enabled!"
fi

