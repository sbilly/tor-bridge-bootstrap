tor-bridge-bootstrap
===================

This script is a fork of https://github.com/micahflee/tor-relay-bootstrap. If you need a relay, go there. If you need a bridge, you've come to the right place.

This is a script to bootstrap a Debian server to be a set-and-forget Tor bridge. I've only tested it in Wheezy, but it should work on any modern Debian or Ubuntu version. Pull requests are welcome.

tor-bridge-bootstrap does this:

* Upgrades all the software on the system
* Adds the deb.torproject.org repository to apt, so Tor updates will come directly from the Tor Project
* Installs and configures Tor to be a bridge that runs obfs3 (but still requires you to manually edit torrc to set Nickname, ContactInfo, etc. for this bridge.)
* Configures sane default firewall rules
* Configures automatic updates
* Installs tlsdate to ensure time is synced
* Helps harden the ssh server
* Gives instructions on what the sysadmin needs to manually do at the end

UPDATE: This project now has highly experimental FreeBSD support.

To use it, set up a Debian server, SSH into it, switch to the root user, and:

```sh
git clone https://github.com/NSAKEY/tor-bridge-bootstrap.git
cd tor-bridge-bootstrap
```

Then edit the ORPort and ExtORPort values in tor-bridge-bootstrap/etc/tor/torrc, tor-bridge-bootstrap/etc/iptables/rules.v4 tor-bridge-bootstrap/etc/iptables/rules.v6. Once that's finished:

```sh
./deb-bootstrap.sh
```
