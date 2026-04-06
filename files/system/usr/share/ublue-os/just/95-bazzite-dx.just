# vim: set ft=make :

# Skeptically verify Bazzite-DX state and virtualization readiness
[group('System')]
dx-status:
    #!/usr/bin/bash
    echo "=== Bazzite-DX Architectural Audit ==="
    echo "1. Kernel Arguments (Actual):"
    cat /proc/cmdline | grep -iE --color "iommu|kvm|preempt" || echo "Warning: Missing IOMMU/KVM kargs in /proc/cmdline!"

    echo -e "\n2. Group Membership Check:"
    DX_GROUPS=("docker" "incus-admin" "libvirt" "dialout" "input" "video" "render" "plugdev")
    for grp in "${DX_GROUPS[@]}"; do
        if groups "$USER" | grep -q "\b$grp\b"; then
            echo "[PASS] $grp"
        else
            echo "[FAIL] $grp (Run: ujust setup-dx-user)"
        fi
    done

    echo -e "\n3. Homebrew Reachability:"
    if command -v brew >/dev/null; then
        echo "[PASS] Brew is in PATH: $(which brew)"
    else
        echo "[FAIL] Brew not found in PATH"
    fi

# Provision the current user for DX groups (Virtualization, Containers, Hardware)
[group('System')]
setup-dx-user:
    #!/usr/bin/bash
    set -euo pipefail
    DX_GROUPS=("docker" "incus-admin" "libvirt" "dialout" "input" "video" "render" "plugdev")
    echo "Provisioning $USER for Developer Experience..."
    for grp in "${DX_GROUPS[@]}"; do
        if getent group "$grp" >/dev/null; then
            if groups "$USER" | grep -q "\b$grp\b"; then
                echo "Already in group: $grp"
            else
                sudo usermod -aG "$grp" "$USER"
                echo "Added to group: $grp"
            fi
        else
            echo "Warning: group $grp not found. Ensure you have rebased to Bazzite-DX."
        fi
    done
    echo "Done! Please log out and back in for group changes to take effect."

# Install fonts from brew
install-fonts:
    #!/usr/bin/bash
    echo "Installing extra fonts..."
    brew bundle --file=/usr/share/ublue-os/homebrew/bazzite-dx-fonts.Brewfile

# Install engineering tools from brew
install-tools:
    #!/usr/bin/bash
    echo "Installing DX engineering tools..."
    brew bundle --file=/usr/share/ublue-os/homebrew/bazzite-dx-tools.Brewfile

# Monitor system performance with eBPF (bpftop)
monitor-performance:
    #!/usr/bin/bash
    echo "Starting eBPF performance monitor (bpftop)..."
    sudo bpftop

# Toggle NVIDIA Open-Source Kernel Modules (GSP Firmware)

# Modern declarative implementation via bootc kargs.d
toggle-nvidia-open:
    #!/usr/bin/bash
    KARGS_FILE="/usr/lib/bootc/kargs.d/05-nvidia-open.toml"
    if [ ! -f "$KARGS_FILE" ]; then
        echo "Enabling NVIDIA Open-Source Kernel Modules (GSP)..."
        echo 'kargs = ["nvidia.NVreg_EnableGpuFirmware=1"]' | sudo tee "$KARGS_FILE" > /dev/null
    else
        echo "Disabling NVIDIA Open-Source Kernel Modules (Restoring Proprietary)..."
        sudo rm "$KARGS_FILE"
    fi
    echo "Done! A system update/rebuild or reboot is required to apply changes."

# Quick system inventory for troubleshooting
system-inventory:
    #!/usr/bin/bash
    echo "Generating system inventory for DX troubleshooting..."
    fastfetch -c /usr/share/ublue-os/bazzite/fastfetch-dx.jsonc || echo "fastfetch-dx preset not found, using basic info:" && uname -a
    echo "Enabled groups: $(groups)"
    echo "Homebrew status: $(brew --version 2>/dev/null || echo 'not installed')"

# Toggle default boot between Steam Game Mode (gamescope-session) and Desktop
toggle-gamemode ACTION="":
    #!/usr/bin/bash
    # Lets the user pick the default SDDM autologin session.
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    ACTION="{{ ACTION }}"

    IMAGE_INFO="/usr/share/ublue-os/image-info.json"
    BASE_IMAGE_NAME=$(jq -r '."base-image-name"' < "$IMAGE_INFO" 2>/dev/null || echo "silverblue")

    # Determine desktop session based on base image (KDE = kinoite, GNOME = silverblue)
    DESKTOP_SESSION="gnome-wayland.desktop"
    if [[ $BASE_IMAGE_NAME == "kinoite" ]]; then
        DESKTOP_SESSION="plasma.desktop"
    fi

    GAMEMODE_SESSION="gamescope-session.desktop"
    CONFIG_FILE="/etc/sddm.conf.d/zz-steamos-autologin.conf"

    current_session="Unknown"
    if [[ -f $CONFIG_FILE ]]; then
        current_session=$(grep -Po '^Session=\K.*' "$CONFIG_FILE" || true)
    fi
    if [[ -z $current_session ]]; then
        # Fallback guess
        current_session="$DESKTOP_SESSION"
    fi

    status_pretty="Unknown"
    if [[ $current_session == "$GAMEMODE_SESSION" ]]; then
        status_pretty="Game Mode"
    elif [[ $current_session == "$DESKTOP_SESSION" ]]; then
        status_pretty="Desktop"
    else
        status_pretty="$current_session"
    fi

    ACTION_LOWER=${ACTION,,}

    if [[ $ACTION_LOWER == "help" ]]; then
        echo "Usage: ujust toggle-gamemode [gamemode|desktop|status|help]"
        echo "If no action is provided you'll be prompted with a picker."
        exit 0
    fi

    if [[ $ACTION_LOWER == "status" ]]; then
        echo -e "Current default session: ${bold}${status_pretty}${normal} (${current_session})"
        exit 0
    fi

    CHOICE=""
    if [[ -z $ACTION_LOWER ]]; then
        echo -e "Current default boot target: ${bold}${status_pretty}${normal}\n"
        echo "Select the default session to boot into:"
        echo ""
        CHOICE=$(ugum choose \
            "Steam Game Mode" \
            "Desktop Session" \
            "Exit without changes")
    else
        case "$ACTION_LOWER" in
            gamemode) CHOICE="Steam Game Mode" ;;
            desktop) CHOICE="Desktop Session" ;;
            *) echo "Unrecognized action: $ACTION" ; exit 1 ;;
        esac
    fi

    case "$CHOICE" in
        "Steam Game Mode")
            target_session="$GAMEMODE_SESSION"
            target_pretty="Game Mode"
            ;;
        "Desktop Session")
            target_session="$DESKTOP_SESSION"
            target_pretty="Desktop"
            ;;
        "Exit without changes"|"")
            echo "No changes made."
            exit 0
            ;;
        *)
            echo "Unknown selection: $CHOICE" >&2
            exit 1
            ;;
    esac

    if [[ $target_session == "$current_session" ]]; then
        echo "Already set to $target_pretty ($target_session). Nothing to do."
        exit 0
    fi

    echo "Updating autologin session to: $target_pretty ($target_session)"
    update_content=$'# Autogenerated by ujust toggle-gamemode\n[Autologin]\nSession='"$target_session"

    if [[ $EUID -ne 0 ]]; then
        echo "Requesting root privileges..."
        echo "$update_content" | sudo tee "$CONFIG_FILE" > /dev/null
    else
        printf '%s\n' "$update_content" > "$CONFIG_FILE"
    fi

    echo -e "${green}${bold}Success:${normal} Default session set to $target_pretty. Reboot or log out to apply."
