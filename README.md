# yazi-config

A yazi setup for Arch Linux with vim-style keys, full mouse support, a clickable favorites panel, confirmation before every move, overwrite, rename and delete, and drag-and-drop into GUI programs. Tested with yazi 26.9.1 and kitty 0.49 on X11.

## Prompt for an AI agent

Copy this block to an agent that has shell access on the target machine.

```text
Set up the yazi file manager on this Arch Linux machine from the repository
https://github.com/shourovrm/yazi-config (SSH: git@github.com:shourovrm/yazi-config.git).

1. Clone it to ~/repos/yazi-config. If the directory already exists, run
   `git -C ~/repos/yazi-config pull --ff-only` instead. Do not create a git
   repository inside ~/.config/yazi.
2. Run `~/repos/yazi-config/install.sh`. It installs missing pacman packages,
   replaces ~/.config/yazi with a symlink to the clone (an existing config is
   moved to ~/.config/yazi.backup-<timestamp>, never deleted), and runs
   `ya pkg install`. If sudo needs a password you cannot type, stop and ask the
   user to run `! sudo pacman -S --needed <the packages the script printed>`,
   then run install.sh again.
3. Verify and report the result of each check:
   - `yazi --version` prints 26.9 or newer.
   - `readlink -f ~/.config/yazi` prints the clone path.
   - `ls ~/.config/yazi/plugins` lists 12 plugins (4 tracked, 8 downloaded).
   - Start yazi once in a terminal and confirm the favorites panel is drawn
     on the left and no error text appears.
4. Machine-specific edits, made only after asking the user:
   - favorites.tsv and the `g` shortcuts in keymap.toml (gh, gc, gl, gd, gD,
     gp, gv, gm, gP, gk, ge) name folders such as ~/MEGA-RMS and ~/Projects.
     Replace or remove the ones that do not exist on this machine.
   - Optional herbstluftwm key: add
     `hc keybind $Mod-e spawn kitty --class yazi -e yazi` to the autostart
     file, after checking that Mod-e is not already bound.
   - Optional drag-out key `X`: needs `ripdrag` from the AUR
     (`paru -S ripdrag`), which requires the user's sudo password.
5. Do not edit any other files, do not run `ya pkg upgrade`, and do not push
   to the repository unless the user asks.
```

## Install

```sh
git clone git@github.com:shourovrm/yazi-config.git ~/repos/yazi-config
~/repos/yazi-config/install.sh
```

`install.sh` is safe to run again. It needs `sudo` only when a package is missing.

## Keys

Press `g?` inside yazi for a one-page cheatsheet (the text is in `cheatsheet.tsv`), or `~` for yazi's own searchable list. The additions on top of yazi's default vim-style keys:

| Keys | Action |
|---|---|
| `dd` `yy` `p` `P` | Cut, copy, paste, paste-and-overwrite. Moves and overwrites ask first. |
| `dt` `dD` | Trash, delete permanently. Both ask first. |
| `r` | Rename. Asks before renaming and warns when the name already exists. |
| `f` + letters | Jump to the first file starting with the typed letters. |
| `F` | Filter the list to matching names. |
| `'1` to `'9`, `ga`, `gx`, `B` | Jump to, add, remove a favorite; show or hide the panel. |
| `X` | Drag the selected files out into a GUI program (needs `ripdrag`). |
| `g?` | Cheatsheet. |

The favorites panel also works with the mouse: left-click opens a folder, right-click removes it.

## Syncing between machines

`~/.config/yazi` is a symlink to this checkout, so every edit is already in the working tree.

```sh
# on the machine where you changed something
cd ~/repos/yazi-config && git add -A && git commit -m "Describe the change" && git push

# on every other machine
cd ~/repos/yazi-config && git pull --ff-only && ya pkg install
```

`ya pkg install` only matters when `package.toml` changed. Restart yazi after pulling.

Two things differ per machine. `favorites.tsv` changes whenever you use `ga` or `gx`, so commit it deliberately or run `git checkout favorites.tsv` to discard it. The `g` folder shortcuts in `keymap.toml` assume the folders exist.

## Contents

| Path | Purpose |
|---|---|
| `yazi.toml`, `keymap.toml`, `init.lua` | Settings, key bindings, plugin setup |
| `package.toml` | Official plugins and their pinned versions, restored by `ya pkg install` |
| `plugins/` | Our own plugins: `favorites` (side panel), `confirm`, `safe-rename`, `type-ahead`. The official ones are downloaded and ignored by git. |
| `favorites.tsv` | The favorites list: `label`, a tab, then a path |
| `cheatsheet.tsv`, `scripts/` | The cheatsheet text and the scripts behind `g?` and `X` |
| `install.sh` | Packages, symlink, plugin download |

## Requirements

Packages: `yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick xclip rofi kitty neovim libnotify` and a Nerd Font. `ripdrag` (AUR) is optional. The cheatsheet needs `rofi`, `Ctrl+t` opens `$TERMINAL` and falls back to `kitty`, and text files open in `neovim`.
