#!/bin/bash
# Helper functions for networking and LXC container management

ALL_CONTAINERS=(red green blue)

function go() {
	ERROR="Usage: go [red|green|blue]"
	[ "$#" -eq 0 ] && echo "$ERROR" >&2 && exit 1

	sudo lxc-console -n "$1"
	echo  # add a newline before the prompt
}

function rl() {
	# lists all containers
	sudo lxc-ls -f
}

function rr() {
	ERROR="Usage: reset [red|green|blue|all]"
	[ "$#" -eq 0 ] && echo "$ERROR" >&2 && exit 1

	if [[ "$1" == "$all" ]]; then
		for name in "${ALL_CONTAINERS[@]}"; do
			rr "$name"
		done
	else
		sudo lxc-stop -n "$1"
		sleep 1
		sudo lxc-start -d -n "$1"
		echo "Waiting for container to boot..."
		rl_wait_lxc_boot "$1"
		echo "Container sucessfully started!"
	fi
}

function rl_wait_lxc_boot() {
	local cmd='systemctl is-system-running 2>/dev/null'
	sudo lxc-attach -n "$1" -- bash -c \
		'while [[ ! "$('"$cmd"')" =~ (running|degraded) ]]; do sleep 1; done'
}

# removes network / internet configuration
function rl_clear_networking()
{
	for ct in red green blue; do
		ip addr flush dev veth-"$ct"
		ip li set dev veth-"$ct" down
		lxc-attach -n "$ct" -- ip addr flush dev eth0
		lxc-attach -n "$ct" -- ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
	done
	iptables -t filter -F
	iptables -t mangle -F
	iptables -t nat -F
	sysctl -q -w net.ipv4.ip_forward=0
}

