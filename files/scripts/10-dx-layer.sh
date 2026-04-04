#!/usr/bin/bash
set -ouex pipefail

echo "::group:: ===$(basename "$0")==="

# Load secure COPR helpers
# shellcheck source=/dev/null
source "$(dirname "$0")/shared/copr-helpers.sh"

# 1. (REMOVED) Official Repositories setup (Migrated to recipe.yml)
# 2. (REMOVED) Bulk Official Package Installation (Migrated to recipe.yml)

# 3. ROCm Logic (AMD Compute)
# rocm doesn't work well on nvidia, only install if non-nvidia image
if [[ ! "${IMAGE_NAME}" =~ nvidia ]]; then
	echo "Installing ROCm packages (AMD GPU detected or non-Nvidia image)..."
	dnf5 install -y \
		rocm-hip \
		rocm-opencl \
		rocm-smi
fi

# 4. Isolated COPR Module Installation
echo "Installing specialized DX COPR packages..."

# uBlue Tools & Workarounds
copr_install_isolated ublue-os/packages \
	ublue-setup-services \
	ublue-os-libvirt-workarounds

# Management & Dev Tools
copr_install_isolated karmab/kcli \
	kcli

copr_install_isolated gmaglione/podman-bootc \
	podman-bootc

echo "DX Layer setup complete."
echo "::endgroup::"
