#!/bin/bash
# Common installer functions for the host and containers

function wait_for_vm_boot() {
	echo "Waiting for the VM to fully boot..."
	while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] && \
		[ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do sleep 2; done
}

