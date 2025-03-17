#!/bin/bash

set -e
set -o pipefail

# Use jemalloc at runtime
if [ "$USE_JEMALLOC" = "true" ]; then
	export LD_PRELOAD=libjemalloc.so.2
fi

# make sure tmp folders have the correct owners and permissions
# so that Ruby can create temporary files
sudo docker/prod/fix-tmp-permissions

exec "$@"
