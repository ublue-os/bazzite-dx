#!/usr/bin/bash
set -ouex pipefail

echo "::group:: ===$(basename "$0")==="

echo "Starting system cleanup..."

# ── 1. Package Manager Cleanup
# Essential for keeping the final image size small
dnf5 clean all

# ── 2. Safe Cache Cleanup
# We ONLY clean application-specific caches.
# We DO NOT touch /tmp/* or /var/tmp/* as they are often bind-mounted by BlueBuild.
rm -rf /var/log/dnf5.log || true

# ── 3. Container Lint
# Validates the container image
bootc container lint || true

echo "Cleanup completed"

echo "::endgroup::"
