# Bazzite Developer Experience (DX)

[![Build Bazzite DX](https://github.com/ublue-os/bazzite-dx/actions/workflows/build.yml/badge.svg)](https://github.com/ublue-os/bazzite-dx/actions/workflows/build.yml)

**Bazzite DX** is a premium, developer-focused edition of [Bazzite](https://bazzite.gg), meticulously engineered to provide the ultimate hybrid of a high-performance gaming platform and a world-class development workstation. It aligns with the "Developer Experience" philosophy of [Bluefin DX](https://docs.projectbluefin.io/bluefin-dx/) and [Aurora DX](https://docs.getaurora.dev/dx/aurora-dx-intro).

---

## 🏗️ Architectural Philosophy: The Smart Matrix

Bazzite-DX utilizes a **Smart Matrix** architecture powered by [BlueBuild](https://blue-build.org). This allows us to maintain a single source of truth while generating **25+ specialized image variants**, including support for Handhelds (Steam Deck/Legion Go), NVIDIA GPUs, and different Desktop Environments (KDE/GNOME).

- **Build System**: BlueBuild (declarative YAML-based) + GitHub Actions.
- **Matrix Architecture**: Supports 25+ variants defined in `image-versions.yaml`.
- **Layer Strategy**: Bazzite DX is a **layer** on top of Bazzite. The primary verification focus is the **Deck** variant family.
- **Primary Audience**: Software engineers using Bazzite as their daily driver.
- **Contribution Model**: **Upstream Target**. All changes must adhere to uBlue-os image standards.

> [!IMPORTANT]
> **Recommended Target**: When developing or testing, always prioritize the `bazzite-deck` base variants, as they are the only ones currently marked as `tested: true` in the matrix.

---

## 🛠️ Core Capabilities

- **Virtualization Stack**: Pre-configured Cockpit, Incus, and QEMU/KVM for advanced workload management.
- **Kernel Debugging**: Deep observability with BCC, BPFTace, and sysprof available out-of-the-box.
- **Container Excellence**: Optimized sockets for Docker and Podman, with `podman-compose` and `podman-tui` for terminal-based management.
- **Language Support**: Seamless Homebrew integration and essential compilers (ccache, flatpak-builder).

---

## 🚀 Installation & Rebasing

To rebase your current Bazzite installation to the DX edition, execute the command corresponding to your variant. 

> [!TIP]
> All images follow the pattern: `ghcr.io/ublue-os/bazzite-dx[-variant][-gnome]:stable`

### Common Variants

| Desktop | Hardware | DX Image (Target) | Base Image (Origin) | Status |
| :--- | :--- | :--- | :--- | :--- |
| **KDE** | Desktop/AMD | `bazzite-dx` | [bazzite](https://github.com/orgs/ublue-os/packages/container/package/bazzite) | Community |
| **KDE** | NVIDIA | `bazzite-dx-nvidia` | [bazzite-nvidia](https://github.com/orgs/ublue-os/packages/container/package/bazzite-nvidia) | Community |
| **KDE** | Steam Deck | `bazzite-dx-deck` | [bazzite-deck](https://github.com/orgs/ublue-os/packages/container/package/bazzite-deck) | **Recommended** |
| **GNOME**| Desktop/AMD | `bazzite-dx-gnome` | [bazzite-gnome](https://github.com/orgs/ublue-os/packages/container/package/bazzite-gnome) | Community |
| **GNOME**| NVIDIA | `bazzite-dx-gnome-nvidia` | [bazzite-gnome-nvidia](https://github.com/orgs/ublue-os/packages/container/package/bazzite-gnome-nvidia) | Community |
| **GNOME**| Steam Deck | `bazzite-dx-deck-gnome` | [bazzite-deck-gnome](https://github.com/orgs/ublue-os/packages/container/package/bazzite-deck-gnome) | **Recommended** |

> [!TIP]
> **Rebase Command**: `rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/[IMAGE_NAME]:stable`

> [!CAUTION]
> **Desktop Environment Lock**: Do not switch between GNOME and KDE variants via rebase. Always stay within the same DE family to avoid internal configuration conflicts.

---

## 👩‍💻 Development Workflow

The project uses `Just` as the primary task runner.

| Command | Description |
| :--- | :--- |
| `just build` | Build the OCI image locally using BlueBuild CLI |
| `just check` | Run `shellcheck` linting and recipe syntax validation |
| `just format` | Automatically format all Bash scripts using `shfmt` |
| `just status` | Display the current image matrix from `image-versions.yaml` |

---

## ✍️ Contribution Guidelines

We welcome contributions following the "Surgical Precision" rule:
1. **Upstream First**: If a fix benefits the entire Bazzite community, submit it to [Bazzite Upstream](https://github.com/ublue-os/bazzite) instead.
2. **Modular Logic**: Keep logic changes within `files/scripts/` to maintain matrix compatibility.
3. **Validation**: All PRs must pass `just check` without warnings.
