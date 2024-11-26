#!/bin/bash
# Global authorized keys
[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

MASTER_PUBKEYS=/etc/ssh/authorized_keys

if [[ -n "$RL_AUTHORIZED_KEYS" && -f "$SRC/$RL_AUTHORIZED_KEYS" ]]; then
	cat "$SRC/$RL_AUTHORIZED_KEYS" >> "$MASTER_PUBKEYS"
	# sanitize + anonymize keys (remove comments etc.)
	sed '/^\s\+$/d; /^#/d;
		s/^\(\S\+\)\s\+\(\S\+\).*$/\1 \2/' "$MASTER_PUBKEYS" > "$MASTER_PUBKEYS.new"
	sort < "$MASTER_PUBKEYS.new" | uniq > "$MASTER_PUBKEYS"
fi

if [[ -f "$MASTER_PUBKEYS" ]]; then
	chown root:root "$MASTER_PUBKEYS"
	chmod 644 "$MASTER_PUBKEYS"

	cat <<EOF >"/etc/ssh/sshd_config.d/10-authorized.conf"
AuthorizedKeysFile .ssh/authorized_keys $MASTER_PUBKEYS
EOF
fi

