# Bazzite DX Copilot Instructions

This document provides essential technical context for AI agents and developers contributing to the Bazzite DX repository.

## Project Overview

**Bazzite DX** is the developer-centric variant of Bazzite. It aims to deliver a "Developer Experience" (DX) equivalent to Bluefin DX and Aurora DX while maintaining Bazzite's gaming and HTPC optimizations.

- **Build System**: Container-native (OCI + bootc-image-builder).
- **Core Base**: `ghcr.io/ublue-os/bazzite-deck:stable`.
- **Primary Audience**: Software engineers using Bazzite as their daily driver.
- **Contribution Model**: **Upstream Target**. All changes must adhere to uBlue-os image standards.

## 🧠 Knowledge Base (MCP Context7)

Refer to these libraries to understand upstream patterns and core infrastructure:

- `/ublue-os/bazzite`: Source image logic and Steam Deck optimizations.
- `/ublue-os/bluefin` & `/ublue-os/aurora`: Reference implementations for DX tooling.
- `/coreos/rpm-ostree`: Core hybrid package management logic.
- `/bootc-dev/bootc`: Bootable Container specifications and implementation.

## 📋 Repository Structure

### Core Configuration

- `Containerfile`: Multi-stage OCI image definition.
- `Justfile`: Task automation for builds, testing, and VM management.
- `disk_config/devel.toml`: Configuration for local development (includes test user).
- `disk_config/prod.toml`: Clean configuration for production/public distribution (no user injection).
- `image-versions.yaml`: Versioning and tagging metadata.

### Directories

- `build_files/`: Modular build scripts (organized from `00-*` to `999-*`).
- `system_files/`: Static configuration files overlaid onto the system root (`/`).

## 🛠️ Development Workflow

### Essential Commands

```bash
# Build the OCI image and generate a local QCOW2 disk image
just rebuild-qcow2 2>&1 | tee output/build.log

# Launch the generated VM (with execution logs)
just run-vm-qcow2 2>&1 | tee output/run.log

# Extract FIRST BOOT logs (critical for troubleshooting atomic/bootc systems)
ssh -p 2222 bazzite@localhost "journalctl -b 0 --no-hostname" > output/first_boot.log

# Stream journal logs continuously for live debugging
ssh -p 2222 bazzite@localhost "journalctl -f" > output/vm_stream.log
```

## 💡 Maintenance & Troubleshooting

### Sudo Credential Caching

When piped to tools like `tee`, `sudo` prompts may fail to interact correctly with the terminal. Proactively cache credentials before starting long builds:

```bash
# Cache sudo credentials
sudo -v

# Run the build pipeline
just rebuild-qcow2 2>&1 | tee output/build.log
```

### Full Interactive Session Logging

To capture an interactive session (including password prompts) for debugging:

```bash
script -c "just rebuild-qcow2" output/session.log
```

## ✍️ Contribution Guidelines

1. **Surgical Precision**: Keep changes focused and minimal to facilitate upstream merging.
2. **Standard Alignment**: Ensure parity with Bluefin/Aurora DX patterns where applicable.
3. **Validation**: All PRs must pass `just check` before submission.
