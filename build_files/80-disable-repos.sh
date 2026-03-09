#!/usr/bin/env bash
set -euo pipefail

echo "::group:: ===$(basename "$0")==="

echo "Disabling all repositories for final image..."

# Use a loop to disable all repos in /etc/yum.repos.d/
# This ensures compliance with the 'Build Firewall' (90-validate-repos.sh)
for repo in /etc/yum.repos.d/*.repo; do
    if [ -f "$repo" ]; then
        echo "Disabling $repo"
        sed -i 's/enabled=1/enabled=0/g' "$repo"
    fi
done

echo "All repositories disabled."
echo "::endgroup::"
