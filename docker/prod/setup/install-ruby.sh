#!/bin/bash
set -eox pipefail

apt-get install -y curl build-essential

RUBYINSTALL_VERSION=0.10.1
KEY_NAME="0xB9515E77"
KEY_FINGERPRINT="04B2 F3EA 6541 40BC C7DA  1B57 54C3 D9E9 B951 5E77"

curl -OL https://raw.github.com/postmodern/postmodern.github.io/main/postmodern.asc
gpg --import postmodern.asc

if [ ! gpg --fingerprint $KEY_NAME | grep "$KEY_FINGERPRINT" ]; then
  echo Fingerprint does not match
  exit 1
fi

curl -OL https://github.com/postmodern/ruby-install/releases/download/v$RUBYINSTALL_VERSION/ruby-install-$RUBYINSTALL_VERSION.tar.gz
curl -OL https://github.com/postmodern/ruby-install/releases/download/v$RUBYINSTALL_VERSION/ruby-install-$RUBYINSTALL_VERSION.tar.gz.asc

gpg --verify ruby-install-$RUBYINSTALL_VERSION.tar.gz.asc ruby-install-$RUBYINSTALL_VERSION.tar.gz

tar -xzvf ruby-install-$RUBYINSTALL_VERSION.tar.gz

cd ruby-install-$RUBYINSTALL_VERSION/

make install
ruby-install --system ruby $1 -- --with-jemalloc --enable-yjit

gem install bundler --no-document

rm -rf ruby-install-$RUBYINSTALL_VERSION/ *.asc ruby-install-$RUBYINSTALL_VERSION.tar.gz /usr/local/bin/ruby-install /usr/local/share/ruby-install/ /usr/local/src/*
