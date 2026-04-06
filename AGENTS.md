# Bazzite DX Copilot Instructions

This document provides essential technical context for AI agents and developers contributing to the Bazzite DX repository.

## Project Overview

**Bazzite DX** is the developer-centric variant of Bazzite. It aims to deliver a "Developer Experience" (DX) equivalent to Bluefin DX and Aurora DX while maintaining Bazzite's gaming and HTPC optimizations.

- **Build System**: BlueBuild (declarative YAML-based) + GitHub Actions.
- **Architectural Philosophy**: **Expert Monolith**. A high-performance, deduplicated layer that provides unique developer workarounds without redundant bloat.
- **Matrix Architecture**: Supports 25+ variants defined in `image-versions.yaml`.
- **Primary Stable Target**: The **Deck** family (`bazzite-dx-deck`) is the only verified stable path in the current matrix (`tested: true`).
- **Primary Audience**: Software engineers using Bazzite as their daily driver.
- **Contribution Model**: **Upstream Target**. All changes must adhere to uBlue-os image standards.

## 🧠 Knowledge Base (MCP Context7)

Refer to these libraries to understand upstream patterns and core infrastructure:

### Core Infrastructure
- `/ublue-os/ucore`: Core uBlue infra.
- `/blue-build/cli` & `blue-build.org/reference`: Build engine documentation.
- `docs.fedoraproject.org/en-US/fedora-coreos`: Fedora CoreOS base.
- `/bootc-dev/bootc`: modern bootc logic.

### Image Development & DX
- `/ublue-os/bazzite`: Steam Deck and gaming optimizations.
- `/ublue-os/bluefin` & `/ublue-os/aurora`: Reference DX patterns.
- `/ublue-os/bluefin-docs`, `/ublue-os/aurora-docs`, `docs.bazzite.gg`: Manuals.

### Package Management & Stratification
- `/homebrew/brew`: Homebrew logic and CLI tool management.
- `ublue-os/tap`: Custom homebrew-tap for system-integration casks (e.g., VSCode).
- `/ublue-os/packages`: uBlue custom RPM specs.

## 🧱 Architectural Guardrails (MANDATORY)

1. **Stratum Protection**: 
   - **Layered (Ostree)**: Performance tools (`bcc`, `bpftrace`, `kcli`) MUST stay in `recipe.yml`. They require kernel header synchronization.
   - **Unlayered (Homebrew)**: VSCode (`visual-studio-code-linux`) and high-velocity CLI tools MUST stay in `bazzite-dx-tools.Brewfile`.
2. **Skeptical Deduplication (DRY)**: 
   - **MANDATORY**: Before adding any package or workaround, verify if it is already present in the Bazzite-base `Containerfile`.
   - **Redundancy Purge**: If a feature is better handled by upstream Bazzite, remove it from the DX layer.
3. **Persistent Excellence**: Prefer automated Systemd services (e.g., `libvirt-workaround.service`) over imperative boot scripts or `ujust` toggles for core infrastructure stability.
4. **Bazaar Compliance**: Bazzite's `hooks.py` relies on VSCode being unlayered to prevent system-level update blocking.

## 🛠️ Workflow Instructions

### Core Configuration

- `recipes/recipe.yml`: Declarative OCI image definition (BlueBuild).
- `Justfile`: Task automation for builds, linting, and formatting.
- `image-versions.yaml`: The "Smart Matrix" - manages all 25+ image variants and digests.
- `config/`: BlueBuild specific configurations.

### Directories

- `files/scripts/`: Modular build scripts (organized from `00-*` to `999-cleanup.sh`).
- `files/justfiles/`: **Custom Recipes**. Place new `ujust` tasks here for injection via the `justfiles` module.
- `files/system/`: **Direct Overrides**. Use for static configuration files overlaid onto the system root (`/`). Use this paths to **overwrite** existing Bazzite system files.

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
