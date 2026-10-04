--- @since 26.8.15
--
-- Asks "are you sure?" before running another yazi action.
--
--   plugin confirm <action> [action arguments] [--title=...] [--only-for-cut]
--
-- Example: `plugin confirm plugin smart-paste --only-for-cut` shows a dialog
-- before a cut (move) is pasted, and pastes copies straight away.

-- Arguments that belong to this plugin and must not be forwarded to the action.
local OWN_ARGUMENTS = { title = true, body = true, only_for_cut = true, ["only-for-cut"] = true }

-- Describes the clipboard of yanked files: how many, and cut or copy.
local describe_yanked = ya.sync(function()
	local count = 0
	for _ in pairs(cx.yanked) do
		count = count + 1
	end
	return { count = count, is_cut = cx.yanked.is_cut }
end)

local function forwarded_arguments(arguments)
	local forwarded = {}
	for position = 2, #arguments do
		forwarded[#forwarded + 1] = arguments[position]
	end
	for key, value in pairs(arguments) do
		if type(key) == "string" and not OWN_ARGUMENTS[key] then
			forwarded[key] = value
		end
	end
	return forwarded
end

local function entry(_, job)
	local arguments = job.args
	local action = arguments[1]
	local only_for_cut = arguments.only_for_cut or arguments["only-for-cut"]

	local title = arguments.title or "Are you sure?"
	local body = arguments.body

	if only_for_cut then
		local yanked = describe_yanked()
		if yanked.count == 0 then
			-- Nothing to paste: let yazi itself say so.
			return ya.emit(action, forwarded_arguments(arguments))
		end
		if not yanked.is_cut then
			return ya.emit(action, forwarded_arguments(arguments))
		end
		title = "Move " .. yanked.count .. " item" .. (yanked.count == 1 and "" or "s") .. " here?"
		body = body or "The originals are removed from their old location."
	end

	local confirmed = ya.confirm {
		pos = { "center", w = 56, h = 9 },
		title = title,
		body = body,
	}
	if confirmed then
		ya.emit(action, forwarded_arguments(arguments))
	end
end

return { entry = entry }
