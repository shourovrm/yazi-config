#!/usr/bin/env bash
# `g?` inside yazi: one-page key cheatsheet as a rofi overlay. Type to filter,
# Esc closes. The text comes from cheatsheet.tsv next to this script's parent.

sheet_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/cheatsheet.tsv"
key_color='#88c0d0'; text_color='#e5e9f0'; heading_color='#eceff4'

escape_markup() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<<"$1"; }

rows=""; heading_rows=""; row_number=0; previous_section=""
while IFS=$'\t' read -r section key action; do
    [ -z "$section" ] || [ "${section:0:1}" = "#" ] && continue
    if [ "$section" != "$previous_section" ]; then
        if [ -n "$previous_section" ]; then
            rows+=$'\n'; row_number=$((row_number + 1))          # blank spacer row
        fi
        rows+="<span weight=\"bold\" foreground=\"$heading_color\">$(escape_markup "$section")</span>"$'\n'
        heading_rows+="${heading_rows:+,}$row_number"; row_number=$((row_number + 1))
        previous_section=$section
    fi
    rows+="<span foreground=\"$key_color\">$(escape_markup "$key")</span>	<span foreground=\"$text_color\">$(escape_markup "$action")</span>"$'\n'
    row_number=$((row_number + 1))
done < "$sheet_file"

printf '%s' "$rows" | rofi -dmenu -i -markup-rows -no-custom -p "Yazi keys" -a "$heading_rows" -selected-row 1 \
    -theme-str "
      window { width: 1280px; }
      inputbar { padding: 8px 14px; }
      entry { placeholder: \"filter…\"; }
      listview { columns: 2; lines: 31; spacing: 0; fixed-columns: true; }
      element { padding: 2px 14px; border-radius: 4px; }
      element-text { tab-stops: [ 200px ]; }
      element normal.active, element alternate.active { text-color: $heading_color; background-color: transparent; }
      element selected.active { background-color: #3b4252; }
      element selected.normal { background-color: #3b4252; text-color: $text_color; }
    " > /dev/null
