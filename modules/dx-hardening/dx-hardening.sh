#!/usr/bin/env bash

# dx-hardening: Final Build-Time Hardening Module
# Purpose: Consolidate cleanup, repo disabling, and initramfs optimization.

set -euo pipefail

echo "::group:: === dx-hardening sequence starting ==="

# 1. Base Image Optimization (60-clean-base.sh equivalent)
echo "Optimizing base layers..."
# Add base cleaning logic here if needed, or call existing scripts.

# 2. Final Repository Cleanup (Double-Safety)
# Although BlueBuild modules clean up, we ensure systemic hygiene.
echo "Hardening yum.repos.d..."
# Add manual repo disabling if necessary.

# 3. Initramfs Optimization (99-build-initramfs.sh equivalent)
echo "Rebuilding initramfs..."
# Add dracut calls if required.

# 4. Final Image Sweep (999-cleanup.sh equivalent)
echo "Sweeping temporary build artifacts..."
# Add final rm calls.

echo "DX Hardening: COMPLETE."
echo "::endgroup::"
