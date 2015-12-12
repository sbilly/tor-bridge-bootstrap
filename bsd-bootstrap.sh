#!/bin/sh

# check for root
if [ `id -u` != 0 ]; then
    echo "Must be root to run script"
    exit
fi

PWD="$(pwd)"

# update software
#echo "== Updating software"
#freebsd-update fetch install
#pkg upgrade

# install tor and related packages
echo "== Installing Tor and related packages"
#pkg install tor-devel obfsproxy git go tlsdate arm
echo 'tor_enable="YES"' >> /etc/rc.conf

# Use an external script to build obfs4proxy from source
setenv GOPATH /root/go
$PWD/obfs4proxy-build.sh

# configure tor
cp $PWD/etc/tor/torrc /usr/local/etc/tor/torrc
sed -ir 's/\/notices.log//' /usr/local/etc/tor/torrc

# Set up syscyl so we can bind to lower ports
echo "net.inet.ip.portrange.reservedhigh=0" >> /etc/sysctl
service sysctl restart

# configure firewall rules
echo "== Configuring firewall rules"
echo 'pf_enable="YES"' >> /etc/rc.conf

# Set variables for your interface and IPs. Yes, this is ugly.
NETWORK=$(ifconfig | head -n 1 | awk '{print $1}' | sed 's/://g')
IPv4=$(ifconfig | grep inet | grep -vE '(inet6|127.0.0.1)' | awk '{print $2}')
IPv6=$(ifconfig | grep inet6 | grep -vE '(fe80::|inet6 ::1)' | awk '{print $2}')

# Overwrite some placeholder text in /etc/pf.conf with the above-mentioned variable values
sed -ir "s/NETWORK_PLACEHOLDER/$NETWORK/g" $PWD/etc/pf.conf
sed -ir "s/IPv4_PLACEHOLDER/$IPv4/g" $PWD/etc/pf.conf
sed -ir "s/IPv6_PLACEHOLDER/$IPv6/g" $PWD/etc/pf.conf

# Finally, copy the firewall rules over and load the pf kernel module.
cp $PWD/etc/pf.conf /etc/pf.conf
kldload pf

# final instructions
echo ""
echo "== Edit /usr/local/etc/tor/torrc"
echo ""
echo ""
echo "== Run 'service tor start'"
