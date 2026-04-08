#!/usr/bin/env bash
set -xeuo pipefail

# Add bazzite-virt and bazzite-dx just files
echo "import \"/usr/share/ublue-os/just/84-bazzite-virt.just\"" >> /usr/share/ublue-os/justfile
echo "import \"/usr/share/ublue-os/just/95-bazzite-dx.just\"" >> /usr/share/ublue-os/justfile
