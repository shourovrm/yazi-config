#!/usr/bin/env bash
# Sets yazi up on Arch Linux from this repository. Safe to run again.
#   1. installs missing packages with pacman (asks for sudo only when needed)
#   2. links ~/.config/yazi to this checkout, keeping any old config as a backup
#   3. downloads the official plugins pinned in package.toml
set -euo pipefail

repo_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
config_link=${XDG_CONFIG_HOME:-$HOME/.config}/yazi

# yazi and its preview helpers, plus what the key bindings call:
# kitty (Ctrl+t), rofi (g?), neovim (opening text), libnotify (drag-out errors),
# xclip (clipboard on X11), a Nerd Font (icons).
packages=(
    yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick
    xclip rofi kitty neovim libnotify ttf-font-nerd
)

missing_packages=$(pacman -T "${packages[@]}" || true)
if [ -n "$missing_packages" ]; then
    echo "Installing: $missing_packages"
    # shellcheck disable=SC2086  # word splitting of the package list is intended
    sudo pacman -S --needed $missing_packages
fi

mkdir -p "$(dirname "$config_link")"
if [ "$(readlink -f "$config_link")" = "$repo_directory" ]; then
    echo "$config_link already points here."
else
    if [ -e "$config_link" ] || [ -L "$config_link" ]; then
        backup_path="$config_link.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$config_link" "$backup_path"
        echo "Moved the old config to $backup_path"
    fi
    ln -s "$repo_directory" "$config_link"
    echo "Linked $config_link -> $repo_directory"
fi

chmod +x "$repo_directory"/scripts/*.sh
ya pkg install

if ! command -v ripdrag >/dev/null 2>&1; then
    echo "Optional: 'paru -S ripdrag' enables the X key (drag files into GUI apps)."
fi
echo "Done. Restart any running yazi to load the config."
