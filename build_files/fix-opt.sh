#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Starting /opt directory fix"

# Move /var/opt to /usr/share/factory/opt
mkdir -p /usr/share/factory/var/opt
mv -Tv /var/opt /usr/lib/opt
mkdir -p /var/opt # Recreate an empty dir, just in case
echo "C+ /var/opt - - - - /usr/share/factory/var/opt" >>/usr/lib/tmpfiles.d/bazzite-factory-opt.conf

log "Fix completed"
