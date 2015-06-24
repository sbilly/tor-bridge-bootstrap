#!/bin/sh

# check for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

PWD="$(pwd)"

# update software
echo "== Updating software"
freebsd-update fetch install
pkg upgrade

# install tor and related packages
echo "== Installing Tor and related packages"
pkg install tor obfsproxy git go tlsdate arm
service tor stop

# Use an external script to build obfs4proxy from source
setenv GOPATH /root/go
$PWD/obfs4proxy-build.sh

# configure tor
cp $PWD/etc/tor/torrc /etc/tor/torrc

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

# configure sshd
ORIG_USER=$(logname)
if [ -n "$ORIG_USER" ]; then
	echo "== Configuring sshd"
	# only allow the current user to SSH in
	echo "AllowUsers $ORIG_USER" >> /etc/ssh/sshd_config
	echo "  - SSH login restricted to user: $ORIG_USER"
	if grep -q "Accepted publickey for $ORIG_USER" /var/log/auth.log; then
		# user has logged in with SSH keys so we can disable password authentication
		sed -i '/^#\?PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config
		echo "  - SSH password authentication disabled"
		if [ $ORIG_USER == "root" ]; then
			# user logged in as root directly (rather than using su/sudo) so make sure root login is enabled
			sed -i '/^#\?PermitRootLogin/c\PermitRootLogin yes' /etc/ssh/sshd_config
		fi
	else
		# user logged in with a password rather than keys
		echo "  - You do not appear to be using SSH key authentication.  You should set this up manually now."
	fi
	service ssh reload
else
	echo "== Could not configure sshd automatically.  You will need to do this manually."
fi

# final instructions
echo ""
echo "== Try SSHing into this server again in a new window, to confirm the firewall isn't broken"
echo ""
echo "== Edit /etc/tor/torrc"
echo ""
echo ""
echo "== REBOOT THIS SERVER"
