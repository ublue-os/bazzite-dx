#!/usr/bin/env sh

# Bazzite-DX: Shell Excellence (Bling)
# Standardized Shell Experience for the uBlue Ecosystem.
# Supports both Bash and ZSH.

# Prevent recursive sourcing (e.g. for atuin/pre-exec)
[ "${BLING_SOURCED:-0}" -eq 1 ] && return
BLING_SOURCED=1

# --- Premium Navigation & Aliases ---
if command -v eza >/dev/null; then
	alias ls='eza --icons=auto --group-directories-first'
	alias ll='eza -l --icons=auto --group-directories-first'
	alias la='eza -a'
	alias lt='eza --tree'
fi

# --- Modern CLI Alternatives ---
if command -v ugrep >/dev/null; then
	alias grep='ugrep'
	alias egrep='ugrep -E'
	alias fgrep='ugrep -F'
fi

if command -v bat >/dev/null; then
	alias cat='bat --style=plain --pager=never'
fi

# --- Intelligent Shell Hooks ---
BLING_SHELL="$(basename "$(readlink /proc/$$/exe)")"

# 1. Mise Activation (Tool Manager)
if command -v mise >/dev/null; then
	eval "$(mise activate "${BLING_SHELL}")"
fi

# 2. Direnv Activation (Directory Environment)
if command -v direnv >/dev/null; then
	eval "$(direnv hook "${BLING_SHELL}")"
fi

# 3. Zoxide Activation (Better 'cd')
if command -v zoxide >/dev/null; then
	eval "$(zoxide init "${BLING_SHELL}")"
fi

# 4. Starship Prompt (Final Prompt Logic)
if command -v starship >/dev/null; then
	eval "$(starship init "${BLING_SHELL}")"
fi

# 5. Atuin History Integration (Optional Sync)
# To enable cloud-native command history, run: atuin register
if command -v atuin >/dev/null; then
	eval "$(atuin init "${BLING_SHELL}")"
fi

# --- Power-User Extras ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'
alias g='git'
alias d='docker'
alias k='kubectl'
