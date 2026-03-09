#!/usr/bin/env bash
set -xeuo pipefail

systemctl enable docker.socket
systemctl enable podman.socket
systemctl enable libvirt-workaround.service
systemctl enable incus-workaround.service
systemctl enable swtpm-workaround.service
systemctl enable ublue-system-setup.service
systemctl --global enable ublue-user-setup.service
systemctl enable bazzite-dx-groups.service
