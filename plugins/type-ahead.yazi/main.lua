--- @since 26.8.15
--
-- Type-ahead jump: press the key, type some letters, and the cursor moves to
-- the first file whose name starts with them (or, failing that, contains them).
-- Enter keeps the cursor where it is; Esc (twice, the first leaves insert mode)
-- closes the prompt and also leaves the cursor where it is.

local find_first_match = ya.sync(function(_, typed_text)
	local wanted = typed_text:lower()
	local first_containing_match = nil

	for _, file in ipairs(cx.active.current.files) do
		local name = file.name:lower()
		if name:sub(1, #wanted) == wanted then
			return tostring(file.url)
		end
		if not first_containing_match and name:find(wanted, 1, true) then
			first_containing_match = tostring(file.url)
		end
	end
	return first_containing_match
end)

local function entry()
	local input = ya.input {
		title = "Jump to:",
		pos = { "top-center", y = 3, w = 40 },
		realtime = true,
		debounce = 0.05,
	}

	while true do
		local typed_text, event = input:recv()
		if not typed_text or event == 1 or event == 2 then
			return
		end

		if typed_text ~= "" then
			local target = find_first_match(typed_text)
			if target then
				ya.emit("reveal", { target })
			end
		end
	end
end

return { entry = entry }
