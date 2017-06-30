#Bash script for installing Swift version on Linux Ubuntu 14.04
#!/bin/bash

set -e

DIR="$(pwd)"
export SWIFT_VERSION=swift-3.1.1-RELEASE
wget https://swift.org/builds/swift-3.1.1-release/ubuntu1404/${SWIFT_VERSION}/${SWIFT_VERSION}-ubuntu14.04.tar.gz
tar xzf $SWIFT_VERSION-ubuntu14.04.tar.gz
export PATH="${PWD}/${SWIFT_VERSION}-ubuntu14.04/usr/bin:${PATH}"
cd "$DIR"
