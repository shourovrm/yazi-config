-- Draws a rounded border around the three panes.
require("full-border"):setup()

-- Shows git status signs in the file list (needs the fetchers in yazi.toml).
require("git"):setup {
	order = 1500,
}

-- Favorites side panel on the left; the list is stored in favorites.tsv.
-- Must come after full-border so the panel is drawn inside its frame.
require("favorites"):setup {
	width = 24,
}
