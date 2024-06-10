#!/bin/bash
# Install user tooling inside the VM
[[ "$INSIDE_INSTALL_SCRIPT" == "1" ]] || { echo "Direct calls not supported!">&2; exit 5; }

# terminal utilities
apt-get install --no-install-recommends -y tree tmux vim-nox nano \
	bash-completion less htop zip unzip git lsof unrar p7zip lzma xz-utils \
	moreutils expect pciutils usbutils lshw mc genisoimage \
	imagemagick iotop sysstat

# networking utils
apt-get install --no-install-recommends -y traceroute tcpdump dsniff rsync \
	net-tools whois s-nail mailutils sharutils telnet dnsutils ftp nmap \
	lynx elinks curl wget iputils-ping iptables-persistent asciinema ncftp \
	host smbclient cifs-utils ldap-utils finger ethtool tshark

# security utils
apt-get install --no-install-recommends -y iptables-persistent ltrace \
	exiftool binwalk sqlmap nikto john netcat-openbsd testdisk foremost \
	dosfstools mtools pwgen

# Build tools + python + dev libraries
apt-get install --no-install-recommends -y build-essential libc6-dev-i386 \
	gdb gdbserver cscope exuberant-ctags strace ltrace valgrind \
	python3 python3-venv python3-pip python3-setuptools libssl-dev libffi-dev \
	gcc-multilib libglib2.0-dev libc6-dbg sqlite3 \
	manpages-posix manpages-posix-dev make-doc glibc-doc-reference

# Add i386 libraries (required for pwndbg)
if uname -m | grep x86_64 >/dev/null; then
	dpkg --add-architecture i386
	apt-get update
	apt-get install -y libc6-dbg:i386 libgcc-s1:i386
fi

# Install a newer neovim (from unstable ppa)
add-apt-repository -y ppa:neovim-ppa/unstable
apt-get -y update && apt-get -y install neovim

# Install GoBuster
GOBUSTER_DEST=/tmp/gobuster.tar.gz
curl --fail --show-error --silent -L -o "$GOBUSTER_DEST" \
	"https://github.com/OJ/gobuster/releases/download/v3.6.0/gobuster_Linux_x86_64.tar.gz"
mkdir /tmp/gobuster/
tar xf "$GOBUSTER_DEST" -C "/tmp/gobuster"
cp -f "/tmp/gobuster/gobuster" /usr/local/bin/gobuster
chmod +x /usr/local/bin/gobuster

