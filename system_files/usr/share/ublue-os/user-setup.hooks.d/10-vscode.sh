#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script vscode user 1 || exit 1

set -x

# Setup VSCode Extensions
EXTENSIONS=(
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-azuretools.vscode-containers"
)

if command -v code >/dev/null 2>&1; then
    echo "Configuring VSCode extensions for DX..."
    for ext in "${EXTENSIONS[@]}"; do
        code --install-extension "$ext" --force
    done
fi
