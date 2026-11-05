# vim: set ft=make :

# Configure docker,incus-admin,libvirt, container manager, serial permissions
[group('system')]
dx-group:
    #!/usr/bin/pkexec bash
    append_group() {
        local group_name="$1"
        if ! grep -q "^$group_name:" /etc/group; then
            echo "Appending $group_name to /etc/group"
            grep "^$group_name:" /usr/lib/group | sudo tee -a /etc/group > /dev/null
        fi
    }

    GROUPS_ADD=("docker" "incus-admin" "libvirt" "dialout")

    for GROUP_ADD in "${GROUPS_ADD[@]}" ; do
        append_group $GROUP_ADD
        usermod -aG $GROUP_ADD {{ `id -un` }}
    done

    echo "Reboot system and log back in to use docker, libvirt, incus, and serial connections."

# Install fonts from brew
install-fonts:
    #!/usr/bin/bash
    echo "Installing extra fonts..."
    brew bundle --file=/usr/share/ublue-os/homebrew/bazzite-dx-fonts.Brewfile

# Install local AI tools (llmman) from brew
install-ai-tools:
    #!/usr/bin/bash
    echo "Installing local AI tools..."
    brew bundle --file=/usr/share/ublue-os/homebrew/bazzite-dx-ai.Brewfile
