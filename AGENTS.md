# Bazzite DX Copilot Instructions

This document provides essential information for coding agents working with the Bazzite DX repository.

## Repository Overview

**Bazzite DX** is the developer-focused variant of Bazzite, aiming to provide the same "Developer Experience" (DX) as Bluefin DX and Aurora DX but on the Bazzite base (Steam Deck/HTPC/Desktop gaming optimized).

- **Type**: Container-based Linux distribution build system.
- **Base**: Fedora Linux + Bazzite infrastructure + DX tooling.
- **Target**: Developers using Bazzite as their primary OS.
- **Role**: **Upstream Contribution Target**. Changes here should follow uBlue-os standards for general use.

## MCP Context7 Libraries

Use these libraries to understand the infrastructure and patterns:

- `/ublue-os/bazzite`: The base Bazzite project logic.
- `/ublue-os/docs.bazzite.gg`: Official Bazzite documentation.
- `/ublue-os/bluefin` & `/ublue-os/aurora`: Reference for DX patterns and infrastructure.
- `/ublue-os/main`: Universal Blue main image logic.
- `/ublue-os/packages`: uBlue custom RPM specs.
- `/ublue-os/devcontainer`: uBlue-os developer experience container patterns.
- `/coreos/rpm-ostree`: Core hybrid package management logic.
- `/bootc-dev/bootc`: Modern Bootable Container implementation for Fedora.

## Repository Structure

### Key Files

- `Containerfile`: Multi-stage build definition.
- `Justfile`: Build automation recipes.
- `image.toml`: Basic image configuration.
- `image-versions.yaml`: Version tagging definitions.

### Key Directories

- `build_files/`: Contains the build logic.
- `system_files/`: System-wide configurations, fonts, and themes.

## Key Features (Curated from AmyOS/Draft PRs)

- **Virtualization Support**: Advanced recipes for VFIO, IOMMU configuration, and KVMFR found in `system_files/usr/share/ublue-os/just/84-bazzite-virt.just`.
- **Networking Optimization**:
  - MAC Address Randomization (AmyOS style) via `00-amyos-random-mac.conf`.
  - Custom DNS Resolver via `00-amyos-dns.conf` for improved privacy/performance.
- **System Preparation**: Optimized group management and app installation scripts.

## Build & Validation

### Essential Commands

```bash
# Validate syntax and formatting
pre-commit run --all-files

# Check Just recipes
just check
```

## Contribution Guidelines

1. **Surgical Changes**: Keep modifications minimal and focused.
2. **DX Parity**: Align with Bluefin DX and Aurora DX patterns where possible.
3. **Upstream Alignment**: This is a contribution target; follow uBlue-os standards.

### Attribution

AI agents must include the "Assisted-by" footer in commits:
`Assisted-by: [Model Name] via Antigravity`
