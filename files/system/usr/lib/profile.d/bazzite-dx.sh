#!/usr/bin/bash
# Bazzite-DX Shell Profile
# Fallback and interactive synchronization for developer tools.
# Ref: https://docs.projectbluefin.io/bluefin-dx/

if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Set common DX productivity aliases
alias l='eza -lh'
alias ll='eza -lha'
alias cat='bat --paging=never'
