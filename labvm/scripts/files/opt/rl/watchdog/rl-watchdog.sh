#!/bin/bash
# RL Watchdog
# v2024.1
#
# Service that ensures failproof Internet + ssh connection, automatically 
# repairing most of students' mistakes that would result in lost connectivity 
# to their VM.

set -e

DEBUG=${DEBUG:-0}
INTF=${INTF:-eth0}
CHECK_SLEEP=${CHECK_SLEEP:-10}

REBOOT_GUARD=/opt/rl/.emergency-reboot-guard

IPTABLES_RULES=(
	"INPUT:-p icmp -j ACCEPT"
	"OUTPUT:-p icmp -j ACCEPT"
	"INPUT:-p tcp --dport ssh -j ACCEPT"
	"OUTPUT:-p tcp --sport ssh -j ACCEPT"
	"INPUT:-p udp --dport 53 -j ACCEPT"
	"OUTPUT:-p udp --sport 53 -j ACCEPT"
)


function log() {
    local _ARGS=()
    [[ "$DEBUG" != "1" ]] || LOG_ARGS+=("-s")
    logger -t auto-mobile "${_ARGS[@]}" "$@"
}

function @s() {
	"$@" &>/dev/null
}

function has_net_access() {
    ping -q -A -w 3 -c 3 8.8.8.8 &>/dev/null && return 0 || return 1
}

function has_valid_dns() {
    host -W 3 -t A google.com | grep "has address" &>/dev/null && return 0 || return 1
}

function iptables_safety_rules() {
	for rule_desc in "${IPTABLES_RULES[@]}"; do
		local CHAIN="${rule_desc%%:*}"
		local RULE="${rule_desc#*:}"
		@s iptables -C "$CHAIN" $RULE || {
			iptables -I "$CHAIN" $RULE
			log "Installed rule: $rule_desc!"
		}
	done
}

function recover_net_access() {
	ifdown -f "${INTF}" || true
	killall dhclient || true
	ip ro del default || true
	ifup -f "${INTF}" || true
	sleep 2
	if ! has_net_access; then
		# interfaces is broken, run dhclient manually
		killall dhclient || true
		dhclient "${INTF}" || true
	fi
}

function recover_dns_resover() {
	cat <<EOF >/etc/resolv.conf
nameserver 8.8.8.8
EOF
}

function emergency_reboot() {
	if [[ -f "$REBOOT_GUARD" ]]; then
    	if [[ -n "$(find "$REBOOT_GUARD" -mmin -100 -print)" ]]; then
			return 0
    	fi
	fi
	touch "$REBOOT_GUARD"
	reboot
}

function loop() {
    while true; do
    	iptables_safety_rules

        if ! has_net_access; then
        	recover_net_access
        	log "Tried to recover net access!"
        	sleep 3
			if ! has_net_access; then
				log "Net recovery failed! Rebooting after a couple of tries..."
				emergency_reboot
			else
				log "... and succeeded!"
				( echo -e \
					"You accidentally brought down VM Internet access :|" \
					"\n.. but it was successfully recovered by rl-watchdog !" \
					"\nPlease try to keep it like this (never go full ifdown)!"; ) | wall
			fi
        	if ! has_valid_dns; then
        		recover_dns_resover
        		log "Tried to recover DNS resolver!"
        	fi

        elif ! has_valid_dns; then
        	recover_dns_resover
        	log "Tried to recover DNS resolver!"
        fi

		sleep "${CHECK_SLEEP}"
	done
}

loop

