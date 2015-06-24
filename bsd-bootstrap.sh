#!/bin/sh

# check for root
if [ `id -u` != 0 ]; then
    echo "Must be root to run script"
    exit
fi

PWD="$(pwd)"

# update software
echo "== Updating software"
freebsd-update fetch install
pkg upgrade

# install tor and related packages
echo "== Installing Tor and related packages"
pkg install tor-devel obfsproxy git go tlsdate arm
echo 'tor_enable="YES"' >> /etc/rc.conf

# Use an external script to build obfs4proxy from source
setenv GOPATH /root/go
$PWD/obfs4proxy-build.sh

# configure tor
cp $PWD/etc/tor/torrc /usr/local/etc/tor/torrc

# configure firewall rules
echo "== Configuring firewall rules"
echo 'pf_enable="YES"' >> /etc/rc.conf

# Set variables for your interface and IPs. Yes, this is ugly.
NETWORK=$(ifconfig | head -n 1 | awk '{print $1}' | sed 's/://g')
IPv4=$(ifconfig | grep inet | grep -vE '(inet6|127.0.0.1)' | awk '{print $2}')
IPv6=$(ifconfig | grep inet6 | grep -vE '(fe80::|inet6 ::1)' | awk '{print $2}')

# Overwrite some placeholder text in /etc/pf.conf with the above-mentioned variable values
sed -ir "s/NETWORK_PLACEHOLDER/$NETWORK/g" $PWD/etc/pf.conf
sed -ir "s/IPv4_PLACEHOLDER/$NETWORK/g" $PWD/etc/pf.conf
sed -ir "s/IPv6_PLACEHOLDER/$NETWORK/g" $PWD/etc/pf.conf

# final instructions
echo ""
echo "== Try SSHing into this server again in a new window, to confirm the firewall isn't broken"
echo ""
echo "== Edit /etc/tor/torrc"
echo ""
echo ""
echo "== REBOOT THIS SERVER"

