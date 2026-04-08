#!/usr/bin/env bash
set -xeuo pipefail

# Add bazzite-dx just file
echo "import \"/usr/share/ublue-os/just/95-bazzite-dx.just\"" >> /usr/share/ublue-os/justfile

# Add Bazaar DX blocklist
sed -i 's@override-eol-markings@  - /usr/share/ublue-os/bazaar/blocklist-dx.yaml\noverride-eol-markings@g' /usr/share/ublue-os/bazaar/main.yaml
