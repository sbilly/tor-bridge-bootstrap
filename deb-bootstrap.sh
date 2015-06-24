#!/bin/bash

# check for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# update software
echo "== Updating software"
apt-get update
apt-get dist-upgrade -y

apt-get install -y lsb-release

# add official Tor repository
if ! grep -q "http://deb.torproject.org/torproject.org" /etc/apt/sources.list; then
    echo "== Adding the official Tor repository"
    echo "deb http://deb.torproject.org/torproject.org `lsb_release -cs` main" >> /etc/apt/sources.list
    gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -
    apt-get update
fi

# install tor and related packages
echo "== Installing Tor and related packages"
apt-get install -y deb.torproject.org-keyring tor tor-arm tor-geoipdb obfsproxy golang libcap2-bin
service tor stop

# Use an external script to build obfs4proxy from source
export GOPATH=/root/go
$PWD/obfs4proxy-build.sh
setcap 'cap_net_bind_service=+ep' /usr/local/bin/obfs4proxy

# configure tor
cp $PWD/etc/tor/torrc /etc/tor/torrc

# configure firewall rules
echo "== Configuring firewall rules"
apt-get install -y debconf-utils
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
apt-get install -y iptables iptables-persistent
cp $PWD/etc/iptables/rules.v4 /etc/iptables/rules.v4
cp $PWD/etc/iptables/rules.v6 /etc/iptables/rules.v6
chmod 600 /etc/iptables/rules.v4
chmod 600 /etc/iptables/rules.v6
iptables-restore < /etc/iptables/rules.v4
ip6tables-restore < /etc/iptables/rules.v6

apt-get install -y fail2ban

# configure automatic updates
echo "== Configuring unattended upgrades"
apt-get install -y unattended-upgrades apt-listchanges
cp $PWD/etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
service unattended-upgrades restart

# install apparmor
apt-get install -y apparmor apparmor-profiles apparmor-utils
sed -i.bak 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 apparmor=1 security=apparmor"/' /etc/default/grub
update-grub

# install tlsdate
if [ "$(lsb_release -cs)" == "wheezy" ]; then
	# tlsdate isn't in wheezy
	if [ "$((echo 3.5; uname -r) | sort -cV 2>&1)" == "" ]; then
		# if we have seccomp (>= linux 3.5) we can backport it
		if ! grep -q "wheezy-backports" /etc/apt/sources.list; then
			echo "deb http://ftp.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list
			apt-get update
		fi
		apt-get install -y tlsdate
	fi
else
	# later than wheezy
	apt-get install -y tlsdate
fi

# final instructions
echo ""
echo "== Edit /etc/tor/torrc"
echo ""
echo ""
echo "== REBOOT THIS SERVER"
