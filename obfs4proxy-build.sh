#!/bin/sh

# This script simply handles the building of obfs4

# First, create a sandbox directory
mkdir -p /root/go

# This section git clones stuff from torproject.org and preps it to our needs.
mkdir -p /root/go/src/git.torproject.org/pluggable-transports/
git clone https://github.com/Yawning/obfs4.git /root/go/src/git.torproject.org/pluggable-transports/obfs4.git
git clone https://github.com/Yawning/goptlib.git /root/go/src/git.torproject.org/pluggable-transports/goptlib.git

# These lines pull in all the dependencies.
git clone https://github.com/agl/ed25519 /root/go/src/github.com/agl/ed25519
git clone https://github.com/dchest/siphash /root/go/src/github.com/dchest/siphash
mkdir -p /root/go/src/golang.org/x/
git clone https://github.com/golang/crypto/ /root/go/src/golang.org/x/crypto
git clone https://github.com/golang/net /root/go/src/golang.org/x/net

# Finally, the build process. This shouldn't take long.
cd /root/go/src/git.torproject.org/pluggable-transports/obfs4.git/obfs4proxy/
echo "== Now building obfs4proxy"
go build
echo "== Build complete."
cp /root/go/src/git.torproject.org/pluggable-transports/obfs4.git/obfs4proxy/obfs4proxy /usr/local/bin/obfs4proxy

