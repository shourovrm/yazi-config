--- @since 26.8.15
--
-- Renames the hovered file, asking for confirmation before the rename happens.
-- A second, stronger warning is shown when the new name already exists, because
-- the existing file would be replaced.

local get_hovered = ya.sync(function()
	local hovered = cx.active.current.hovered
	if not hovered then
		return nil
	end
	return {
		name = hovered.name,
		path = tostring(hovered.url),
		directory = tostring(cx.active.current.cwd),
	}
end)

local function entry()
	local hovered = get_hovered()
	if not hovered then
		return
	end

	local new_name, event = ya.input {
		title = "Rename:",
		value = hovered.name,
		pos = { "hovered", w = 50 },
	}
	if event ~= 1 or not new_name or new_name == "" or new_name == hovered.name then
		return
	end

	local target_path = new_name:sub(1, 1) == "/" and new_name or (hovered.directory .. "/" .. new_name)
	local would_replace = fs.cha(Url(target_path)) ~= nil

	local confirmed = ya.confirm {
		pos = { "center", w = 60, h = 10 },
		title = would_replace and "Replace the existing file?" or "Rename this file?",
		body = hovered.name .. "  ->  " .. new_name,
	}
	if not confirmed then
		return
	end

	-- `-n` refuses to clobber, `-f` is only used after the user accepted the replacement.
	local overwrite_flag = would_replace and "-f" or "-n"
	local status, error_message = Command("mv"):arg({ overwrite_flag, "--", hovered.path, target_path }):status()
	if not status or not status.success then
		ya.notify {
			title = "Rename failed",
			content = tostring(error_message or "mv returned an error"),
			timeout = 5,
			level = "error",
		}
		return
	end
	ya.emit("reveal", { target_path })
end

return { entry = entry }
