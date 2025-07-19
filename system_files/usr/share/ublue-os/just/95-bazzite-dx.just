# vim: set ft=make :

# Install fonts from brew
install-fonts:
    #!/usr/bin/bash
    echo "Installing extra fonts..."
    brew bundle --file=/usr/share/ublue-os/homebrew/bazzite-dx-fonts.Brewfile
