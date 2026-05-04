#!/usr/bin/env bash

set -euo pipefail

source /usr/lib/ublue/setup-services/libsetup.sh

version-script run-privileged-setup user 1 || exit 0

echo "Running all privileged units"

pkexec /usr/libexec/ublue-privileged-setup