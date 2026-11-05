#!/usr/bin/bash
set -xeuo pipefail

dnf5 install -y \
    android-tools \
    bcc \
    bpftop \
    bpftrace \
    ccache \
    flatpak-builder \
    git-subtree \
    google-noto-sans-fonts \
    nicstat \
    numactl \
    podman-machine \
    podman-tui \
    python3-ramalama \
    restic \
    rclone \
    sysprof \
    tiptop \
    usbmuxd \
    waypipe \
    zsh

dnf5 remove -y \
    mesa-libOpenCL

dnf5 --setopt=install_weak_deps=False install -y \
    rocm-hip \
    rocm-opencl \
    rocm-clinfo \
    rocm-smi \
    qemu \
    libvirt \
    qemu-kvm \
    virt-manager \
    edk2-ovmf \
    guestfs-tools

dnf5 install --enable-repo="copr:copr.fedorainfracloud.org:ublue-os:packages" -y \
    ublue-setup-services

# Adding repositories should be a LAST RESORT. Contributing to Terra or `ublue-os/packages` is much preferred
# over using random coprs. Please keep this in mind when adding external dependencies.
# If adding any dependency, make sure to always have it disabled by default and _only_ enable it on `dnf install`

dnf5 config-manager addrepo --from-repofile="https://packages.microsoft.com/yumrepos/vscode/config.repo"
dnf5 config-manager setopt vscode-yum.enabled=0
dnf5 install --enable-repo="vscode-yum" -y \
    code

docker_pkgs=(
    containerd.io
    docker-buildx-plugin
    docker-ce
    docker-ce-cli
    docker-compose-plugin
)
dnf5 config-manager addrepo --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
dnf5 config-manager setopt docker-ce-stable.enabled=0
dnf5 install -y --enable-repo="docker-ce-stable" "${docker_pkgs[@]}"

# Load iptable_nat module for docker-in-docker.
# See:
#   - https://github.com/ublue-os/bluefin/issues/2365
#   - https://github.com/devcontainers/features/issues/1235
mkdir -p /etc/modules-load.d && cat >>/etc/modules-load.d/ip_tables.conf <<EOF
iptable_nat
EOF
