#!/usr/bin/env bash
set -xeuo pipefail

systemctl enable docker.socket
systemctl enable podman.socket
