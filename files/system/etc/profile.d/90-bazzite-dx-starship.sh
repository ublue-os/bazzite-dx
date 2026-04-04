# shellcheck shell=sh
# Bluefin-DX pattern: Initialize starship if present
command -v starship >/dev/null 2>&1 || return 0

if [ "$(basename "$(readlink /proc/$$/exe)")" = "bash" ]; then
	eval "$(starship init bash)"
fi

if [ "$(basename "$(readlink /proc/$$/exe)")" = "zsh" ]; then
	eval "$(starship init zsh)"
fi
