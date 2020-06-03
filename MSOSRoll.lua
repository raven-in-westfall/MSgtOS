-- TODO:
--	Get MS/OS sort working
--	There is a 250 char limit in SendAddOnMessage.... need to get around that.

local MSgtOS, addon_variables = ...

local rarity_names = { 'Poor', 'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary' }
local Dialog = LibStub("LibDialog-1.0")
local player_name = GetUnitName('player')
local current_roll_tracker = nil
local current_roll_text = nil
local legacy_rolls = {}
local roll_opened = false
local master_looter = true
local already_rolled = false

local send_chat_message = function(text)
	DEFAULT_CHAT_FRAME:AddMessage("[MS > OS] ".. text, 0.45, 0.0, 1.0)
end

local insert_into_current_tracker = function(roll_type, roll_user, roll_score)
	if roll_type == 'MS' or roll_type == 'OS' then
		if current_roll_tracker[roll_type][roll_score] == nil then
			current_roll_tracker[roll_type][roll_score] = {}
		end
		table.insert(current_roll_tracker[roll_type][roll_score], roll_user)
	elseif roll_type == 'passes' then
		current_roll_tracker[roll_type][roll_user] = true
	end
	current_roll_tracker['rollers'][roll_user] = true
	-- If someone passed something invalid, IDC, maybe oneday raise an exception?
end

local get_sorted_keys = function(table_to_sort, ascending)
	local keys = {}
	for key in pairs(table_to_sort) do
		table.insert(keys, key)
	end

	if decending then
		table.sort(keys, function(a, b) return a > b end)
	else
		table.sort(keys, function(a, b) return a < b end)
	end
	return keys
end

local generate_roll_text = function()
	--print('RAID_CLASS_COLORS')
	--for key, value in pairs(RAID_CLASS_COLORS) do
	--	print(key)
	--end

	-- First load everyone in the raid
	local new_text = '|cffffff00Loot Rolls\nFor |r'.. current_roll_tracker['item_link'] .."\n\n"
	local raid_classes = {}
--	for i = 1, MAX_RAID_MEMBERS do
--		user_name, _, _, _, user_class, _, _, _, _, _, _ = GetRaidRosterInfo(i);
--		if user_name ~= nil then
--			raid_classes[ user_name ] = user_class
--		end
--	end

	raid_classes['u1'] = true
	raid_classes['u2'] = true
	raid_classes['u3'] = true
	raid_classes['u4'] = true
	raid_classes['u5'] = true
	raid_classes['u6'] = true
	raid_classes['u7'] = true
	raid_classes['u8'] = true
	raid_classes['u9'] = true
	raid_classes['u10'] = true
	raid_classes['u11'] = true
	raid_classes['u12'] = true
	raid_classes['u13'] = true
	raid_classes['u14'] = true
	raid_classes['u15'] = true
	raid_classes['u16'] = true
	raid_classes['u17'] = true
	raid_classes['u18'] = true
	raid_classes['u19'] = true
	raid_classes['u20'] = true
	raid_classes['u21'] = true
	raid_classes['u22'] = true
	raid_classes['u23'] = true
	raid_classes['u24'] = true
	raid_classes['u25'] = true
	raid_classes['u26'] = true
	raid_classes['u27'] = true
	raid_classes['u28'] = true
	raid_classes['u29'] = true
	raid_classes['u30'] = true
	raid_classes['u31'] = true
	raid_classes['u32'] = true
	raid_classes['u33'] = true
	raid_classes['u34'] = true
	raid_classes['u35'] = true
	raid_classes['u36'] = true
	raid_classes['u37'] = true
	raid_classes['u38'] = true
	raid_classes['Chegg'] = true
	raid_classes['Anabella'] = true


	-- Extract out the main spec rolls
	new_text = new_text .."|cffffff00Main Spec Rolls|r\n"
	local sorted_keys = get_sorted_keys(current_roll_tracker['MS'], true)
	local has_roll = false
	for _, key in ipairs(sorted_keys) do
		for _, user in pairs(current_roll_tracker['MS'][key]) do
			new_text = new_text .. key .." ".. user .."\n"
			raid_classes[user] = nil
			has_roll = true
		end
	end
	if not has_roll then new_text = new_text .."|cff666666None|r\n" end


	-- Extract out the off spec rolls
	new_text = new_text .."\n|cffffff00Off Spec Rolls|r\n"
	local sorted_keys = get_sorted_keys(current_roll_tracker['OS'], true)
	has_roll = false
	for _, key in ipairs(sorted_keys) do
		for _, user in pairs(current_roll_tracker['OS'][key]) do
			new_text = new_text .. key .." ".. user .."\n"
			raid_classes[user] = nil
			has_roll = true
		end
	end
	if not has_roll then new_text = new_text .."|cff666666None|r\n" end


	-- Extract out the pass rolles
	new_text = new_text .."\n|cffffff00Passed|r\n"
	has_roll = false
	local sorted_keys = get_sorted_keys(current_roll_tracker['passes'], false)
	for _, key in ipairs(sorted_keys) do
		new_text = new_text .. key .."\n"
		raid_classes[key] = nil
		has_roll = true
	end
	if not has_roll then new_text = new_text .."|cff666666None|r\n" end
	


	-- Show the remaining raid memebers
	new_text = new_text .."\n|cffffff00No Action|r\n"
	has_roll = false
	local sorted_keys = get_sorted_keys(raid_classes)
	for _, key in ipairs(sorted_keys) do
		if raid_classes[key] ~= nil then
			new_text = new_text .."|cff666666".. key .."|r\n"
			has_roll = true
		end
	end
	if not has_roll then new_text = new_text .."|cff666666None|r\n" end

	-- Finally set the current roll data to this new text
	current_roll_text = new_text
end

local process_incoming_roll_request = function(addon_msg)
	-- If there is not a current roll we don't need to do anything
	if current_roll_tracker == nil then
		return
	end

	-- only the master looters machine is alowed to generate a roll
	if not master_looter then
		return
	end

	local roll_type = string.sub(addon_msg, 1, 6)
	local roll_user = string.sub(addon_msg, 7)
	local roll_value = random(100)

	-- Don't allow a player to roll again
	if current_roll_tracker['rollers'][roll_user] ~= nil then
		return
	end

        local client_message = ''
	if roll_type == 'msroll' then
		roll_type = 'MS'
	elseif roll_type == 'osroll' then
		roll_type = 'OS'
	elseif roll_type == 'passes' then
		role_type = 'passes'
	else
		send_chat_message("Invalid roll request: ".. addon_msg)
	end

	insert_into_current_tracker(roll_type, roll_user, roll_value)
	client_message = roll_user .. " ".. roll_type .." ".. roll_value

	generate_roll_text()
       	C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", "rollupdate ".. client_message, "RAID");

	-- Maybe we want to broadcast the roll? IDK, maybe a setting
       	-- roll_message = player_name .." rolls ".. my_roll .." (1-100) ".. spec_type
       	-- C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", "rollupdate ".. player_name .." ".. my_roll .." ".. roll_type, "RAID");
	--  DEFAULT_CHAT_FRAME:AddMessage(addon_msg, 1, 1, 0)
end

local loot_roll_frame = CreateFrame("Frame", "SwatterErrorFrame", UIParent)
loot_roll_frame:Hide()
loot_roll_frame:SetPoint("CENTER", "UIParent", "CENTER")
loot_roll_frame:SetFrameStrata("TOOLTIP")
loot_roll_frame:SetHeight(580)
loot_roll_frame:SetWidth(300)
loot_roll_frame:SetBackdrop({
	bgFile = "Interface/Tooltips/ChatBubble-Background",
	edgeFile = "Interface/Tooltips/ChatBubble-BackDrop",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 32, right = 32, top = 32, bottom = 32 }
})
loot_roll_frame:SetBackdropColor(0,0,0, 1)
--Swatter.Error:SetScript("OnShow", Swatter.ErrorShow)
loot_roll_frame:SetMovable(true)
loot_roll_frame:SetClampedToScreen(true)
loot_roll_frame:SetToplevel(true)
loot_roll_frame:SetScript("OnMouseDown", function() loot_roll_frame:StartMoving() end)
loot_roll_frame:SetScript("OnMouseUp", function() loot_roll_frame:StopMovingOrSizing() end)

-- local dragger = CreateFrame("Button", nil, loot_roll_frame)
-- dragger:SetPoint("TOPLEFT", loot_roll_frame, "TOPLEFT", 10,-5)
-- dragger:SetPoint("TOPRIGHT", loot_roll_frame, "TOPRIGHT", -10,-5)
-- dragger:SetHeight(8)
-- dragger:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")

local close_button = CreateFrame("Button", "", loot_roll_frame, "OptionsButtonTemplate")
close_button:SetText("Close")
close_button:SetPoint("BOTTOMRIGHT", loot_roll_frame, "BOTTOMRIGHT", -10, 10)
close_button:SetScript("OnClick", function() loot_roll_frame:Hide() end)
close_button:SetFrameLevel(5)

local next_button = CreateFrame("Button", "", loot_roll_frame, "OptionsButtonTemplate")
next_button:SetText("Next >")
next_button:SetPoint("BOTTOMRIGHT", close_button, "BOTTOMLEFT", -5, 0)
next_button:SetScript("OnClick", Swatter.ErrorNext)
next_button:SetFrameLevel(5)

local prev_button = CreateFrame("Button", "", loot_roll_frame, "OptionsButtonTemplate")
prev_button:SetText("< Prev")
prev_button:SetPoint("BOTTOMRIGHT", next_button, "BOTTOMLEFT", -5, 0)
prev_button:SetScript("OnClick", Swatter.ErrorPrev)
prev_button:SetFrameLevel(5)

local scroll_frame = CreateFrame("ScrollFrame", "", loot_roll_frame, "UIPanelScrollFrameTemplate")
scroll_frame:SetPoint("TOPLEFT", loot_roll_frame, "TOPLEFT", 20, -20)
scroll_frame:SetPoint("RIGHT", loot_roll_frame, "RIGHT", -30, 0)
scroll_frame:SetPoint("BOTTOM", close_button, "TOP", 0, 10)

local loot_info = CreateFrame("EditBox", "", scroll_frame)
loot_info:SetWidth(450)
loot_info:SetHeight(485)
loot_info:SetMultiLine(true)
loot_info:SetAutoFocus(false)
loot_info:SetFontObject(GameFontHighlight)
loot_info:SetScript("OnEditFocusGained", function() loot_info:ClearFocus() end )

scroll_frame:SetScrollChild(loot_info)


local update_roll_window = function(new_roll_data)
        -- If we are not the master looter we need to extract the information into our local cache of the roll
	-- Master looter has already done this when they generated the roll for the user
	-- This also prevents someone from sending the ML a crafted addon message
	if new_roll_data and not master_looter then
		-- split the new_roll_data on ' ' elements will be user, roll_type, roll
		local roll_data = {}
		for substring in new_roll_data:gmatch("%S+") do
			table.insert(roll_data, substring)
		end
		insert_into_current_tracker(roll_data[2], roll_data[2], roll_data[3])
		generate_roll_text()
	end
	loot_info:SetText(current_roll_text)
	loot_roll_frame:Show()
end


-- This openes up a roll for an item, everyone needs to run this so their client knows if a roll is opened
local start_roll = function(item_link)
	if current_roll_tracer ~= nil then
		table.insert(legacy_rolls, current_roll_text)
	end
	current_roll_tracker = {
		['item_link'] = item_link,
		['rollers'] = {},
		['passes'] = {},
		['MS'] = {},
		['OS'] = {},
	}
	roll_opened = true
	-- Force the window to open for everyone
	generate_roll_text()
	update_roll_window()
end


-- This ends a roll for an item, everyone needs to run this so their client knows if a roll ends
local end_roll = function()
	if current_roll_tracer ~= nil then
		table.insert(legacy_rolls, current_roll_text)
		if master_looter then
			SendChatMessage("Roll for ".. current_roll_tracer['item_link'] .." has ended", "RAID")
		end
	end
	current_roll_tracer = nil
	roll_opened = false
	already_rolled = false
end

SLASH_MSGTOSSTARTROLL1 = '/raidroll'
SlashCmdList.MSGTOSSTARTROLL = function(msg, ...)
	-- the raidroll command can only be be used by ML
	if not master_looter then
		return
	end

	if msg == nil then
		send_chat_message("You need to specify an item to roll on")
		return
	end
	if msg == 'end' then
		if current_roll_tracker == nil then
			send_chat_message("There is no roll currently opened")
			return
		end
		SendChatMessage("Roll has ended for ".. current_roll_tracker['item_link'], "RAID")
		C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", "end", "RAID")
	else
		if current__roll_tracker ~= nil then
			send_chat_message("You first need to end the existing roll for")
			return
		end
		item_name, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(msg)
		if item_name == nil then
			send_chat_message("Unable to lookup item ".. msg .." did you properly link the item?")
			return
		end

		item_prio = 'None'
		if addon_variables['prio_list'][item_name] ~= nil then
			item_prio = addon_variables['prio_list'][item_name]
		end
		SendChatMessage("Roll for ".. item_link, "RAID_WARNING")
		SendChatMessage("Prio for ".. item_link ..": ".. item_prio, "RAID")
		C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", "start ".. item_link, "RAID")
	end
end

local make_roll = function(roll_type)
	if not roll_opened then
		print_no_roll_message()
		return
	end
	if alredy_rolled then
		send_chat_message("You have already rolled on this item")
		return
	end
	already_rolled = true
	C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", roll_type .." ".. player_name, "RAID");
end

SLASH_MSGTOSOSROLL1 = '/osroll'
SlashCmdList.MSGTOSOSROLL = function(msg, ...)
	make_roll('osroll')
end

SLASH_MSGTOSMSROLL1 = '/msroll'
SlashCmdList.MSGTOSMSROLL = function(msg, ...)
	make_roll('msroll')
end

SLASH_MSGTOSPASSROLL1 = '/pass'
SlashCmdList.MSGTOSPASSROLL = function(msg, ...)
	make_roll('passes')
end

print_no_roll_message = function()
	send_chat_message("There is not currently a roll opened")
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(self, event, ...)
	if event == "CHAT_MSG_ADDON" then
		message_type, addon_msg, level = ...
		if message_type == 'MSgtOS_ROLL' then
			if string.sub(addon_msg, 1, 6) == 'start ' then
				start_roll(string.sub(addon_msg, 7))
			elseif addon_msg == 'end' then
				end_roll()
			elseif string.sub(addon_msg, 1, 11) == 'rollupdate ' then
				update_roll_window(string.sub(addon_msg, 12))
			else
				process_incoming_roll_request(addon_msg)
			end
		end
	end
end)


C_ChatInfo.RegisterAddonMessagePrefix("MSgtOS_ROLL")
