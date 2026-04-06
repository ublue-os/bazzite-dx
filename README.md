# Bazzite Developer Experience (DX)

[![Build Bazzite DX](https://github.com/ublue-os/bazzite-dx/actions/workflows/build.yml/badge.svg)](https://github.com/ublue-os/bazzite-dx/actions/workflows/build.yml)

**Bazzite DX** is a premium, developer-focused edition of [Bazzite](https://bazzite.gg), meticulously engineered to provide the ultimate hybrid of a high-performance gaming platform and a world-class development workstation. It aligns with the "Developer Experience" philosophy of [Bluefin DX](https://docs.projectbluefin.io/bluefin-dx/) and [Aurora DX](https://docs.getaurora.dev/dx/aurora-dx-intro).

---

## 🏗️ Architectural Philosophy: The Smart Matrix

Bazzite-DX utilizes a **Smart Matrix** architecture powered by [BlueBuild](https://blue-build.org). This allows us to maintain a single source of truth while generating **25+ specialized image variants**, including support for Handhelds (Steam Deck/Legion Go), NVIDIA GPUs, and different Desktop Environments (KDE/GNOME).

- **Build System**: BlueBuild (declarative YAML-based) + GitHub Actions.
- **Package Strategy**: **Hybrid Stratification** (Layered for Kernel-bound tools | Unlayered for User-space IDEs/CLI).
- **Matrix Architecture**: Supports 25+ variants defined in `image-versions.yaml`.
- **Primary Audience**: Software engineers using Bazzite as their daily driver.
- **Contribution Model**: **Upstream Target**. All changes must adhere to uBlue-os image standards.

> [!IMPORTANT]
> **Recommended Target**: Always prioritize the `bazzite-deck` variants for development, as they are the primary verified target path (`tested: true`).

---

## 🛠️ Core Capabilities

- **Hybrid DX Stack**: Strategic placement of tools for maximum performance and stability.
  - **Layered (rpm-ostree)**: High-performance observability (`bcc`, `bpftrace`, `bpftop`, `iotop`) and virtualization (`kcli`, `incus`, `libvirt`).
  - **Unlayered (Homebrew)**: Visual Studio Code (`visual-studio-code-linux` cask) and high-velocity CLI suites (`eza`, `bat`, `fzf`, `zoxide`).
- **Container Excellence**: Optimized sockets for Docker and Podman, with `podman-compose` and native system-level `podman-tui`.
- **Professional Flatpaks**: Essential DX apps pre-installed (system-wide): `Extension Manager`, `GNOME Boxes`, `Mission Center`, and `ZapZap`.
- **Tap Integration**: Seamless use of `ublue-os/tap` to deliver system-integrated casks without image bloat.

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

### 🔧 Post-Rebase Configuration
Immediately after rebasing and rebooting, run the following command to provision your user for the DX environment:
```bash
ujust setup-dx-user
```
This adds your user to the necessary groups (`docker`, `libvirt`, `incus-admin`, etc.) without modifying the system-default files.

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
| `just rebase-local` | Rebase the current system to the local build for testing |

---

## ✍️ Contribution Guidelines

We welcome contributions following the "Surgical Precision" rule:
1. **Upstream First**: If a fix benefits the entire Bazzite community, submit it to [Bazzite Upstream](https://github.com/ublue-os/bazzite) instead.
2. **Modular Logic**: Keep logic changes within `files/scripts/` to maintain matrix compatibility.
3. **Validation**: All PRs must pass `just check` without warnings.
