-- TODO:
--	Fiz was offline when he got ML, make the addon check for ML when its started
--		This should work, needs testing
--	Get MS/OS wrking

local MSgtOS, addon_variables = ...

local rarity_names = { 'Poor', 'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary' }
local Dialog = LibStub("LibDialog-1.0")
local player_name = GetUnitName('player')
local current_roll_tracker = nil
local legacy_rolls = {}
local roll_opened = false
local message_color = {
        ['r'] = 0.45,
        ['g'] = 0.0,
        ['b'] = 1.0,
}

local roll_tracker_dialog = Dialog:Register("MSgtOSRollTracker", {
	text = "Loot Tracker",
	width = 300,
	on_show = function(self, data)
		display_sorted_roll_tracker(self, current_roll_tracker)
	end,
	buttons = {
		{ text = "End Roll", },
		{ text = CLOSE, },
	},
	show_while_dead = true,
	hide_on_escape = true,
})

local start_roll = function()
	if current_roll_tracer ~= nil then
		table.insert(legacy_rolls, current_roll_tracer)
	end
	current_roll_tracker = {
		['item_name'] = item_name,
		['passes'] = {},
		['MS'] = {},
		['OS'] = {},
	}
	roll_opened = true
end

local make_roll = function(main_spec)
	local my_roll = random(100)
	local spec_type = 'OS'
	if main_spec then spec_type = 'MS' end
	roll_message = player_name .." rolls ".. my_roll .." (1-100) ".. spec_type
	C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", roll_message, "RAID");
end

SLASH_MSGTOSOSROLL1 = '/osroll'
SlashCmdList.MSGTOSOSROLL = function(msg, editbox)
	if roll_opened then
		make_roll(false)
	else
		print_no_roll_message()
	end
end

SLASH_MSGTOSMSROLL1 = '/msroll'
SlashCmdList.MSGTOSMSROLL = function(msg, editbox)
	if roll_opened then
		make_roll(true)
	else
		print_no_roll_message()
	end
end

SLASH_MSGTOSPASSROLL1 = '/pass'
SlashCmdList.MSGTOSPASSROLL = function(msg, editbox)
	if roll_opened then
		C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", player_name .." passes", "RAID");
	else
		print_no_roll_message()
	end
end

print_no_roll_message = function()
	DEFAULT_CHAT_FRAME:AddMessage("[MS > OS] There is not currently a roll opened", message_color["r"], message_color["g"], message_color["b"])
end

process_incoming_roll = function(addon_msg)
	DEFAULT_CHAT_FRAME:AddMessage(addon_msg, 1, 1, 0)
	if current_roll_tracker ~= nil then
		-- Split this message and put it in our roll tracker
		local message_segments = {}
		for i in string.gmatch(addon_msg, "%S+") do
			table.insert(message_segments, i)
		end
		local roll_type = nil
		local roll_value = nil
		if message_segments[2] == 'passes' then
			table.insert(current_roll_tracker['passes'], message_segments[1])
		else
			roll_type = message_segments[5]
			roll_value = message_segments[3]
			if current_roll_tracker[roll_type][roll_value] == nil then
				current_roll_tracker[roll_type][roll_value] = {}
			end
			table.insert(current_roll_tracker[roll_type][roll_value], message_segments[1])
		end
		display_sorted_roll_tracker()
	end
end

local sort_roll_tracker_field = function(tbl)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return tbl[a] < tbl[b]
	end)

	return keys
end

display_sorted_roll_tracker = function(dialog, roll_to_display)
	--print('RAID_CLASS_COLORS')
	--for key, value in pairs(RAID_CLASS_COLORS) do
	--	print(key)
	--end

	-- First load everyone in the raid
	local new_text = 'Loot Tracker\n'
        local raid_classes = {}
        for i = 1, MAX_RAID_MEMBERS do
		user_name, _, _, _, user_class, _, _, _, _, _, _ = GetRaidRosterInfo(i);
		if user_name ~= nil then
			raid_classes[ user_name ] = user_class
        	end
	end


	-- Extract out the main spec rolls
	new_text = new_text .."Main Spec Rolls\n"
	if current_roll_tracker['MS'] ~= nil then
		local sorted_keys = sort_roll_tracker_field(current_roll_tracker['MS'])
		for _, key in ipairs(sorted_keys) do
			print(current_roll_tracker['MS'][key][1])
			print(current_roll_tracker['MS'][key][2])
			new_text = new_text .. value[2] .."  ".. value[1] .."\n"
		end
	else
		new_text = new_text .."None\n"
	end


	print("TESTING")
--	test_dir = {
--		{'Raven', '12'},
--		{'Chegg', '98'},
--	}
--	table.sort(test_dir, sort_roll_tracker_field)
--	for item, value in pairs(test_dir) do
--		print(value[1])
--		print(value[2])
--	end
--	print("END_TESTING")
--
--	-- Extract out the off spec rolls
--	new_text = new_text .."Off Spec Rolls\n"
--	if current_roll_tracker['OS'] ~= nil then
--		table.sort(current_roll_tracker['OS'], sort_roll_tracker_field)
--		for item, value in pairs(current_roll_tracker['OS']) do
--			new_text = new_text .. value[2] .."  ".. value[1] .."\n"
--		end
--	else
--		new_text = new_text .."None\n"
--	end
--
--
--	-- Extract out the pass rolles
--	new_text = new_text .."Passed\n"
--	if current_roll_tracker['passes'] ~= nil then
--		table.sort(current_roll_tracker['passes'], sort_roll_tracker_field)
--		for item, value in pairs(current_roll_tracker['passes']) do
--			for key,value in pairs(value) do
--				new_text = new_text .. value .."\n"
--			end
--		end
--	else
--		new_text = new_text .."None\n"
--	end


	-- Show the remaining raid memebers
	new_text = new_text .."No Action\n"

	print(new_text)
	-- Dialog:Spawn("MSgtOSRollTracker", loot_table)
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(self, event, ...)
	if event == "CHAT_MSG_ADDON" then
		message_type, addon_msg, level = ...
                if message_type == 'MSgtOS_ROLL' then
			process_incoming_roll(addon_msg)
		elseif message_type == 'MSgtOS_ROLL_START' then
			start_roll()
		end
	end
end)


C_ChatInfo.RegisterAddonMessagePrefix("MSgtOS_ROLL")
