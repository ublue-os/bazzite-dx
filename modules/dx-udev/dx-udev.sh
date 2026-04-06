#!/usr/bin/env bash

# Bazzite-DX: Udev Provisioning (Android/Hardware)
# Automates the ingestion of standard hardware debugging rules.

set -euo pipefail

# --- Android (ADB/Fastboot) Rules ---
# Source: https://github.com/M0Rf30/android-udev-rules
TARGET_PATH="/usr/lib/udev/rules.d/51-android.rules"
URL="https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules"

echo "Ingesting Android udev rules from $URL..."
curl -sSL "$URL" -o "$TARGET_PATH"
chmod a+r "$TARGET_PATH"

# --- Group Setup (sysusers) ---
# Create adbusers group for rootless ADB access
echo "Setting up adbusers group via sysusers.d..."
cat <<EOF >/usr/lib/sysusers.d/android-udev.conf
g adbusers - -
EOF

if [ -f "$TARGET_PATH" ]; then
	echo "OK: Android rules and sysusers placed."
else
	echo "ERROR: Failed to download android rules!"
	exit 1
fi
