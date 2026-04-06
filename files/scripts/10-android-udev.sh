#!/usr/bin/env bash

# 10-android-udev.sh: Ingest external android udev rules
# Source: https://github.com/M0Rf30/android-udev-rules

set -euo pipefail

echo "::group:: === Ingesting Android udev rules ==="

TARGET_PATH="/usr/lib/udev/rules.d/51-android.rules"
URL="https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules"

echo "Downloading rules from $URL..."
curl -sSL "$URL" -o "$TARGET_PATH"

if [ -f "$TARGET_PATH" ]; then
	echo "OK: Android rules placed at $TARGET_PATH"
else
	echo "ERROR: Failed to download android rules!"
	exit 1
fi

echo "::endgroup::"
