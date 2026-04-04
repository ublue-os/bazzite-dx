# Bazzite DX Copilot Instructions

This document provides essential technical context for AI agents and developers contributing to the Bazzite DX repository.

## Project Overview

**Bazzite DX** is the developer-centric variant of Bazzite. It aims to deliver a "Developer Experience" (DX) equivalent to Bluefin DX and Aurora DX while maintaining Bazzite's gaming and HTPC optimizations.

- **Build System**: BlueBuild (declarative YAML-based) + GitHub Actions.
- **Matrix Architecture**: Supports 25+ variants defined in `image-versions.yaml`.
- **Architectural Layering**: Bazzite-DX is a **layer** applied to Bazzite bases. **Never treat it as a standalone image**.
- **Primary Stable Target**: The **Deck** family (`bazzite-dx-deck`) is the only verified stable path in the current matrix (`tested: true`).
- **Primary Audience**: Software engineers using Bazzite as their daily driver.
- **Contribution Model**: **Upstream Target**. All changes must adhere to uBlue-os image standards.

## 🧠 Knowledge Base (MCP Context7)

Refer to these libraries to understand upstream patterns and core infrastructure:

- `/ublue-os/bazzite`: Source image logic and Steam Deck optimizations.
- `/ublue-os/bluefin` & `/ublue-os/aurora`: Reference implementations for DX tooling.
- `blue-build.org/reference`: Main build engine documentation.
- `/bootc-dev/bootc`: Bootable Container specifications and implementation.

## 📋 Repository Structure

### Core Configuration

- `recipes/recipe.yml`: Declarative OCI image definition (BlueBuild).
- `Justfile`: Task automation for builds, linting, and formatting.
- `image-versions.yaml`: The "Smart Matrix" - manages all 25+ image variants and digests.
- `config/`: BlueBuild specific configurations.

### Directories

- `files/scripts/`: Modular build scripts (organized from `00-*` to `999-cleanup.sh`).
- `files/system/`: Static configuration files overlaid onto the system root (`/`).

## 🛠️ Development Workflow

### Essential Commands

```bash
# Build the OCI image locally using BlueBuild CLI
just build

# Run shellcheck linting and recipe syntax validation
just check

# Automatically format all Bash scripts using shfmt
just format
```

## 💡 Maintenance & Troubleshooting

### The Smart Matrix logic
Bazzite-DX uses a dynamic matrix. When adding new packages:
1. Prefer adding to `recipes/recipe.yml` for declarative management.
2. Use `files/scripts/20-variant-adjust.sh` for logic that depends on `$IMAGE_NAME` (e.g., Deck vs. Desktop).
3. Ensure `999-cleanup.sh` remains minimal to avoid BlueBuild mount conflicts.

### Security Compliance
All third-party repositories (COPR) MUST be disabled by the `90-validate-repos.sh` script before the image is finalized.

## ✍️ Contribution Guidelines

1. **Surgical Precision**: Keep changes focused and minimal to facilitate upstream merging.
2. **Standard Alignment**: Ensure parity with Bluefin/Aurora DX patterns where applicable.
3. **Validation**: All PRs must pass `just check` before submission.
