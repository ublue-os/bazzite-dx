#!/usr/bin/bash
set -ouex pipefail

# shellcheck disable=SC1091
source /usr/lib/ublue/setup-services/libsetup.sh

version-script tailscale privileged 1 || exit 0

# Configure Tailscale operator for the current user
# $PKEXEC_UID is provided by ublue-privileged-setup which runs these hooks
USER_NAME=$(getent passwd "$PKEXEC_UID" | cut -d: -f1)

if command -v tailscale >/dev/null 2>&1; then
	echo "Configuring Tailscale operator for $USER_NAME..."
	tailscale set --operator="$USER_NAME"
fi
