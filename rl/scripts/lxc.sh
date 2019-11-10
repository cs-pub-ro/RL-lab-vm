#!/bin/bash
# Creates and configured the LXC containers
set -e

# the containers to be created
CONTAINERS=(red green blue)

# use HTTP for keyserver access (some firewalls filter HKP)
LXC_CREATION_ARGS=(
	--dist="ubuntu" --release="bionic" --arch="amd64"
	--keyserver "hkp://p80.pool.sks-keyservers.net:80"
)

# disable the default lxcbr0
sed -i "s/USE_LXC_BRIDGE=.*/USE_LXC_BRIDGE=\"false\"/g" /etc/default/lxc-net
systemctl restart lxc-net

function lxc_container_exists()
{
	lxc-ls -1 --defined 2>/dev/null | grep "^$1$" >/dev/null
}

for name in "${CONTAINERS[@]}"; do
	if ! lxc_container_exists "$name"; then
		echo "Installing LXC container $name..." >&2
		lxc-create -t download -n "$name" -- "${LXC_CREATION_ARGS[@]}"
	fi
done

# copy container configuration scripts
function lxc_container_copy_configs()
{
	local lxc_dir=/var/lib/lxc/$1
	local lxc_src="$SRC/lxc/$1"
	local lxc_common="$SRC/lxc/_common/"
	# stop the container if running
	lxc-stop -q -n "$1" || true
	# copy the configuration files
	cp -f "$lxc_src/config" "$lxc_dir/config"
	rsync -avh --exclude /config "$lxc_common/" "$lxc_src/" "$lxc_dir/rootfs/"
	rsync -avh "$SRC/files/home/bashrc" "$lxc_dir/rootfs/home/.bashrc"
	chmod 755 "$lxc_dir/rootfs/install.sh"
	# start the container
	lxc-start -d -n "$1"
	# configure networking
	ip addr add "10.90.$2.1/24" dev veth-"$1"
	# run the installation script
	lxc-attach -n "$1" -- /install.sh "$2"
}

# enable forwarding and NAT
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -j MASQUERADE

i=1
for name in "${CONTAINERS[@]}"; do
	echo "Configuring LXC container $name..." >&2
	lxc_container_copy_configs "$name" "$i"
	i=$(( $i + 1 ))
done

echo "LXC Containers:"
lxc-ls -f

