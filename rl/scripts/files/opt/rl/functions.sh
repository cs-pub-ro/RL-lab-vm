#!/bin/bash
# Helper functions for networking and LXC container management

ALL_CONTAINERS=(red green blue)

function go() {
	ERROR="Usage: go [red|green|blue]"
	[ "$#" -eq 0 ] && echo "$ERROR" >&2 && exit 1

	sudo lxc-console -n "$1"
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

