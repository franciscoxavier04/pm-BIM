#!/bin/bash
set -eox pipefail

apt-get install -y curl build-essential

RUBYINSTALL_VERSION=0.10.1

curl -OL https://github.com/postmodern/ruby-install/releases/download/v$RUBYINSTALL_VERSION/ruby-install-$RUBYINSTALL_VERSION.tar.gz

tar -xzvf ruby-install-$RUBYINSTALL_VERSION.tar.gz

cd ruby-install-$RUBYINSTALL_VERSION/

make install
ruby-install --system ruby $1 -- --with-jemalloc --enable-yjit

gem install bundler --no-document
