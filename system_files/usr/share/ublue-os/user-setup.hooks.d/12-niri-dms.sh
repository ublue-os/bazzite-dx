#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script niri-dms user 1 || exit 1

set -euo pipefail

# Ensure the DMS config fragment directory exists.
# niri will fail to start if any include target is missing, so these
# placeholder files must be present before the user's first niri session.
# DMS will overwrite them with real content on its first run.
mkdir -p "${HOME}/.config/niri/dms"
for f in colors layout alttab binds; do
    [[ -f "${HOME}/.config/niri/dms/${f}.kdl" ]] || touch "${HOME}/.config/niri/dms/${f}.kdl"
done

# Seed niri config for users whose home predates this image version.
if [[ ! -f "${HOME}/.config/niri/config.kdl" ]]; then
    mkdir -p "${HOME}/.config/niri"
    cp /etc/skel/.config/niri/config.kdl "${HOME}/.config/niri/config.kdl"
fi

# Ensure screenshot directory exists
mkdir -p "${HOME}/Pictures/Screenshots"
