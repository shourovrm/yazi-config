--- @since 26.8.15
--
-- Favorites side panel.
--
-- Draws a clickable list of favorite folders to the left of the parent pane.
-- The list lives in `favorites.tsv` next to this config (one `label<TAB>path`
-- per line), so it can be edited by hand or through the commands below.
--
--   plugin favorites jump <n>      go to the n-th favorite
--   plugin favorites add           add the current directory (asks for a label)
--   plugin favorites remove [n]    remove the n-th favorite, or the current directory
--   plugin favorites reload        re-read favorites.tsv
--   plugin favorites toggle        show or hide the panel

local home_directory = os.getenv("HOME") or ""

local function favorites_file_path()
	local config_directory = os.getenv("YAZI_CONFIG_HOME")
		or ((os.getenv("XDG_CONFIG_HOME") or (home_directory .. "/.config")) .. "/yazi")
	return config_directory .. "/favorites.tsv"
end

local function expand_home(path)
	if path == "~" then
		return home_directory
	elseif path:sub(1, 2) == "~/" then
		return home_directory .. path:sub(2)
	end
	return path
end

local function contract_home(path)
	if path == home_directory then
		return "~"
	elseif home_directory ~= "" and path:sub(1, #home_directory + 1) == home_directory .. "/" then
		return "~" .. path:sub(#home_directory + 1)
	end
	return path
end

local function load_favorites()
	local items = {}
	local file = io.open(favorites_file_path(), "r")
	if not file then
		return items
	end
	for line in file:lines() do
		local is_blank_or_comment = line:match("^%s*$") or line:match("^%s*#")
		if not is_blank_or_comment then
			local label, path = line:match("^(.-)\t(.+)$")
			if label and path then
				items[#items + 1] = { label = label, path = expand_home(path) }
			end
		end
	end
	file:close()
	return items
end

local function save_favorites(items)
	local file = io.open(favorites_file_path(), "w")
	if not file then
		return false
	end
	file:write("# label<TAB>path   -- edited by the favorites plugin, hand edits are fine\n")
	for _, item in ipairs(items) do
		file:write(item.label, "\t", contract_home(item.path), "\n")
	end
	file:close()
	return true
end

-- Synchronous accessors: these run on the main thread, where the plugin state
-- and the `cx` context live. The asynchronous `entry` below calls them.
local get_items = ya.sync(function(state) return state.items or {} end)

local set_items = ya.sync(function(state, items)
	state.items = items
	ui.render()
end)

local get_current_directory = ya.sync(function() return tostring(cx.active.current.cwd) end)

local toggle_panel = ya.sync(function(state)
	state.visible = not state.visible
	ui.render()
end)

local function basename(path)
	return path:match("([^/]+)/*$") or path
end

local function notify(content)
	ya.notify { title = "Favorites", content = content, timeout = 3, level = "info" }
end

local function add_current_directory()
	local directory = get_current_directory()
	local items = get_items()
	for _, item in ipairs(items) do
		if item.path == directory then
			return notify("Already a favorite: " .. item.label)
		end
	end

	local label, event = ya.input {
		title = "Favorite label:",
		value = basename(directory),
		pos = { "top-center", y = 3, w = 40 },
	}
	if event ~= 1 or not label or label == "" then
		return
	end

	items[#items + 1] = { label = label, path = directory }
	save_favorites(items)
	set_items(items)
	notify("Added " .. label)
end

local function remove_favorite(requested_index)
	local items = get_items()
	local index = tonumber(requested_index)
	if not index then
		local directory = get_current_directory()
		for position, item in ipairs(items) do
			if item.path == directory then
				index = position
			end
		end
	end
	if not index or not items[index] then
		return notify("Nothing to remove here")
	end

	local confirmed = ya.confirm {
		pos = { "center", w = 50, h = 8 },
		title = "Remove favorite?",
		body = items[index].label .. "  (" .. contract_home(items[index].path) .. ")",
	}
	if not confirmed then
		return
	end

	table.remove(items, index)
	save_favorites(items)
	set_items(items)
end

local function jump_to_favorite(requested_index)
	local item = get_items()[tonumber(requested_index) or 0]
	if item then
		ya.emit("cd", { item.path })
	else
		notify("No favorite number " .. tostring(requested_index))
	end
end

local function setup(state, options)
	options = options or {}
	local panel_width = options.width or 24

	state.items = load_favorites()
	state.visible = true

	-- The sidebar is a component like Parent/Current/Preview. It is added to
	-- Tab so that the mouse dispatcher in Root finds it through `reflow`.
	local Sidebar = { _id = "favorites-sidebar" }

	function Sidebar:new(area, tab)
		return setmetatable({ _area = area, _tab = tab }, { __index = self })
	end

	function Sidebar:reflow() return { self } end

	-- The deepest favorite that contains the current directory is highlighted.
	function Sidebar:active_index()
		local current = tostring(self._tab.current.cwd)
		local best_index, best_length = nil, -1
		for index, item in ipairs(state.items) do
			local contains = current == item.path
				or (item.path ~= "/" and current:sub(1, #item.path + 1) == item.path .. "/")
			if contains and #item.path > best_length then
				best_index, best_length = index, #item.path
			end
		end
		return best_index
	end

	function Sidebar:redraw()
		if self._area.w < 4 then
			return {}
		end

		local text_width = self._area.w - 1
		local active_index = self:active_index()
		local lines = { ui.Line({ ui.Span(" Favorites"):style(ui.Style():fg("blue"):bold()) }) }

		for index, item in ipairs(state.items) do
			local is_active = index == active_index
			local shortcut = index <= 9 and tostring(index) or " "
			local style = is_active and ui.Style():fg("cyan"):bold() or ui.Style()
			local line = ui.Line({
				ui.Span(" " .. shortcut .. " "):style(ui.Style():fg("darkgray")),
				ui.Span("󰉋 " .. item.label):style(style),
			})
			line:truncate { max = text_width, ellipsis = ui.Span("…") }
			lines[#lines + 1] = line
		end

		return {
			ui.Text(lines):area(self._area),
			ui.Bar(ui.Edge.RIGHT):area(self._area):symbol(th.mgr.border_symbol):style(th.mgr.border_style),
		}
	end

	-- Mouse events. Row 1 is the title, so favorite n is on row n + 1.
	function Sidebar:click(event, up)
		if up then
			return
		end
		local item_index = event.y - self._area.y
		local item = state.items[item_index]
		if not item then
			return
		end

		if event.is_left then
			ya.emit("cd", { item.path })
		elseif event.is_right then
			ya.emit("plugin", { "favorites", "remove", item_index })
		end
	end

	function Sidebar:scroll(event, step) end

	function Sidebar:touch(event, step) end

	-- Reserve room on the left of the tab, then let the stock layout split the
	-- remainder into parent/current/preview.
	local stock_layout = Tab.layout
	Tab.layout = function(self, ...)
		local full_area = self._area
		local width = state.visible and math.min(panel_width, full_area.w // 4) or 0
		local columns = ui.Layout()
			:direction(ui.Layout.HORIZONTAL)
			:constraints({ ui.Constraint.Length(width), ui.Constraint.Fill(1) })
			:split(full_area)

		self._sidebar_area = columns[1]
		self._area = columns[2]
		stock_layout(self, ...)
		self._area = full_area
	end

	-- full-border draws its frame around the whole tab, one cell in from the
	-- edge, so the sidebar leaves one cell of padding on the top, bottom and left.
	local stock_build = Tab.build
	Tab.build = function(self, ...)
		stock_build(self, ...)
		local area = self._sidebar_area:pad(ui.Pad(1, 0, 1, 1))
		table.insert(self._children, Sidebar:new(area, self._tab))
	end
end

local function entry(_, job)
	local action = job.args[1]
	if action == "jump" then
		jump_to_favorite(job.args[2])
	elseif action == "add" then
		add_current_directory()
	elseif action == "remove" then
		remove_favorite(job.args[2])
	elseif action == "reload" then
		set_items(load_favorites())
		notify("Reloaded favorites")
	elseif action == "toggle" then
		toggle_panel()
		ya.emit("app:resize", {})
	end
end

return { setup = setup, entry = entry }
