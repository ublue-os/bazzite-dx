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

# Copy entries into /usr/lib/passwd and /usr/lib/group
if [ -f /etc/passwd ]; then
    out=$(grep -v "root" /etc/passwd) || true
    if [ -n "$out" ]; then
        echo
        echo Moving the following passwd users to /usr/lib/passwd
        echo "$out"
        echo "$out" >> /usr/lib/passwd
        echo "root:x:0:0:root:/root:/bin/bash" > /etc/passwd
    fi
fi
if [ -f /etc/group ]; then
    out=$(grep -v "root\|wheel" /etc/group) || true
    if [ -n "$out" ]; then
        echo
        echo Moving the following group entries to /usr/lib/group
        echo "$out"
        echo "$out" >> /usr/lib/group
        echo "root:x:0:" > /etc/group
        echo "wheel:x:10:" >> /etc/group
    fi
fi

# Extra lock files created by container processes that might cause issues
rm -rf \
    /etc/.pwd.lock \
    /etc/passwd- \
    /etc/group- \
    /etc/shadow- \
    /etc/gshadow- \
    /etc/subuid- \
    /etc/subgid-

# Commit and lint container
bootc container lint || true

log "Cleanup completed"
