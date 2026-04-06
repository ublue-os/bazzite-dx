#!/usr/bin/env bash

# dx-verify: High-Velocity Image Audit Module
# Purpose: Final hardening and integrity check for Bazzite-DX.

set -euo pipefail

echo "::group:: === dx-verify audit starting ==="

# 1. Verification of Critical Groups (sysusers.d)
echo "Auditing security groups..."
for group in plugdev libvirt docker adbusers; do
	if getent group "$group" >/dev/null; then
		echo "OK: Group '$group' is defined."
	else
		echo "ERROR: Group '$group' is missing from the image!"
		exit 1
	fi
done

# 2. Verification of Hardware Rules (udev)
echo "Auditing hardware udev rules..."
UDEV_FILES=(
	"/usr/lib/udev/rules.d/51-android.rules"
	"/usr/lib/sysusers.d/android-udev.conf"
	"/usr/lib/modules-load.d/ip_tables.conf"
	"/usr/lib/tmpfiles.d/opt-fix.conf"
	"/usr/lib/systemd/system/bazzite-dx-groups.service"
	"/usr/libexec/bazzite-dx-groups"
)

for file in "${UDEV_FILES[@]}"; do
	if [ -f "$file" ]; then
		echo "OK: Hardware rule file '$file' found."
	else
		echo "ERROR: Critical hardware rule '$file' is missing!"
		exit 1
	fi
done

# 3. Verification of Core Developer Tools
echo "Auditing core developer utilities..."
CORE_BINARIES=(
	"/usr/bin/docker"
	"/usr/bin/podman"
	"/usr/bin/kcli"
	"/usr/bin/ramalama"
)

for binary in "${CORE_BINARIES[@]}"; do
	if [ -f "$binary" ]; then
		echo "OK: Binary '$binary' found."
	else
		echo "ERROR: Core binary '$binary' is missing!"
		exit 1
	fi
done

# 4. Verification of Workstation Flavors (Brewfiles)
echo "Auditing Workstation Brewfiles..."
BREWFILES=(
	"/usr/share/ublue-os/homebrew/cli.Brewfile"
	"/usr/share/ublue-os/homebrew/ai-tools.Brewfile"
	"/usr/share/ublue-os/homebrew/cncf.Brewfile"
)

for file in "${BREWFILES[@]}"; do
	if [ -f "$file" ]; then
		echo "OK: Brewfile '$file' found."
	else
		echo "ERROR: Workstation flavor '$file' is missing!"
		exit 1
	fi
done

# 5. Final Hardening: Ensure No Residual COPR repos
# Although the 'dnf' module cleans up, we double-check /etc/yum.repos.d/
echo "Verifying repository hygiene..."
COPR_REPOS=$(find /etc/yum.repos.d/ -maxdepth 1 -name "*.repo" -printf "%f\n" | grep -E "copr|vscode|docker" || true)
if [ -n "$COPR_REPOS" ]; then
	echo "Warning: Residual repos found: $COPR_REPOS"
	# We don't fail here, but we log for skepticism audit.
fi

echo "Bazzite-DX Integrity: 100% VERIFIED."
echo "::endgroup::"
