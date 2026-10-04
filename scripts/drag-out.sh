#!/usr/bin/env bash
# Opens a small drag source window (ripdrag) holding the given files, so they can
# be dropped into GUI programs such as LibreOffice, a browser or a chat window.
# Called from yazi with the selected (or hovered) files as arguments.

if ! command -v ripdrag >/dev/null 2>&1; then
    notify-send "Drag out needs ripdrag" "Install it with: paru -S ripdrag"
    exit 1
fi

# --and-exit closes the window after one drop, --all drags every file as one batch.
error_output=$(ripdrag --and-exit --all "$@" 2>&1 >/dev/null) || {
    notify-send "ripdrag failed" "$error_output"
    exit 1
}
