#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Starting system cleanup"

# Clean package manager cache
dnf5 clean all

# Clean temporary files
rm -rf /tmp/* || true

# Cleanup the entirety of `/var`.
# None of these get in the end-user system and bootc lints get super mad if anything is in there
rm -rf /var
mkdir -p /var/tmp
chmod -R 1777 /var/tmp

# Commit and lint container
bootc container lint || true

log "Cleanup completed"
