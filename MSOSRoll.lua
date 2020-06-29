-- TODO:
--	Get MS/OS sort working
--	There is a 250 char limit in SendAddOnMessage.... need to get around that.

local MSgtOS, addon_variables = ...

local rarity_names = { 'Poor', 'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary' }
local Dialog = LibStub("LibDialog-1.0")
local player_name = GetUnitName('player')
local current_roll_tracker = nil
local current_roll_index = nil
local legacy_rolls = {}
local roll_opened = false
local already_rolled = false

local MSGTOSRoll = {
	current_roll_text = nil,
	master_looter = false,
	tool_tip_link = nil,
}

local check_if_i_am_master_looter = function()
	MSGTOSRoll.master_looter = false
        local user_raid_index = UnitInRaid("player")
        -- if not ina raid index will be nil
        if user_raid_index then
                local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo( user_raid_index )
                if isML and not MSGTOSRoll.master_looter then
			addon_variables['send_chat_message']("Congratz, you are the ML")
                        MSGTOSRoll.master_looter = true
                end
        end
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

	if ascending == nil or ascending then
		table.sort(keys, function(a, b) return a > b end)
	else
		table.sort(keys, function(a, b) return a < b end)
	end
	return keys
end

local generate_roll_text = function()
	local new_text = '|cffffff00Loot Rolls|r\n'
	if current_roll_tracker == nil then
		MSGTOSRoll.current_roll_text = new_text .."|cff666666No Current Roll|r"
		return
	end
	local class_colors = {}
	-- First load everyone in the raid
	new_text = new_text ..'|cffffff00Item: |r'.. current_roll_tracker['item_link'] .."\n\n"
	local raid_classes = {}
	local raid_colors = {}
	local user_name
	local user_class
	for i = 1, MAX_RAID_MEMBERS do
		user_name, _, _, _, user_class, _, _, _, _, _, _ = GetRaidRosterInfo(i);
		if user_name ~= nil then
			if class_colors[user_class] == nil then
				r, g, b, hex = GetClassColor(string.upper(user_class))
				class_colors[user_class] = hex
			end
			raid_classes[ user_name ] = true
			raid_colors[ user_name] = class_colors[user_class]
		end
	end

	-- Extract out the main spec rolls
	new_text = new_text .."|cffffff00Main Spec Rolls|r\n"
	local sorted_keys = get_sorted_keys(current_roll_tracker['MS'])
	local has_roll = false
	for _, key in ipairs(sorted_keys) do
		for _, user in pairs(current_roll_tracker['MS'][key]) do
			new_text = new_text .. key .." |c".. raid_colors[user] .. user .."|r\n"
			raid_classes[user] = nil
			has_roll = true
		end
	end
	if not has_roll then new_text = new_text .."|cff666666None|r\n" end


	-- Extract out the off spec rolls
	new_text = new_text .."\n|cffffff00Off Spec Rolls|r\n"
	local sorted_keys = get_sorted_keys(current_roll_tracker['OS'])
	has_roll = false
	for _, key in ipairs(sorted_keys) do
		for _, user in pairs(current_roll_tracker['OS'][key]) do
			new_text = new_text .. key .." |c".. raid_colors[user] .. user .."|r\n"
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
		new_text = new_text .."|c".. raid_colors[key] .. key .."|r\n"
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
	if not has_roll then
		new_text = new_text .."|cff666666None|r\n"
		-- If we are the master looter and there are no rollers left we can end the roll
		if MSGTOSRoll.master_looter then
			MSGTOSRoll.end_roll()
		end
	end

	-- Finally set the current roll data to this new text
	MSGTOSRoll.current_roll_text = new_text
end

local process_incoming_roll_request = function(addon_msg)
	-- If there is not a current roll we don't need to do anything
	if current_roll_tracker == nil then
		return
	end

	-- only the master looters machine is alowed to generate a roll
	if not MSGTOSRoll.master_looter then
		return
	end

	local roll_type = string.sub(addon_msg, 1, 6)
	local roll_user = string.sub(addon_msg, 8)
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
		roll_type = 'passes'
	else
		addon_variables['send_chat_message']("Invalid roll request: ".. addon_msg)
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

function MSGTOSRoll.show_previous_roll()
	if current_roll_index == nil then
		current_roll_index = table.getn(legacy_rolls)
	else
		current_roll_index = current_roll_index - 1
	end
	if current_roll_index == 1 then
		MSGTOSRoll.prev_button:Disable()
	else
		MSGTOSRoll.prev_button:Enable()
	end
	MSGTOSRoll.next_button:Enable()
	MSGTOSRoll.loot_info:SetText(legacy_rolls[current_roll_index])
end

function MSGTOSRoll.show_next_roll()
	current_roll_index = current_roll_index + 1
	if current_roll_index > table.getn(legacy_rolls) then
		MSGTOSRoll.next_button:Disable()
		MSGTOSRoll.loot_info:SetText(MSGTOSRoll.current_roll_text)
	else
		MSGTOSRoll.loot_info:SetText(legacy_rolls[current_roll_index])
		MSGTOSRoll.next_button:Enable()
	end
	MSGTOSRoll.prev_button:Enable()
end

MSGTOSRoll.loot_roll_frame = CreateFrame("Frame", "MSOSRollFrame", UIParent)
MSGTOSRoll.loot_roll_frame:Hide()
MSGTOSRoll.loot_roll_frame:SetPoint("CENTER", "UIParent", "CENTER")
MSGTOSRoll.loot_roll_frame:SetFrameStrata("TOOLTIP")
MSGTOSRoll.loot_roll_frame:SetHeight(580)
MSGTOSRoll.loot_roll_frame:SetWidth(300)
MSGTOSRoll.loot_roll_frame:SetBackdrop({
	bgFile = "Interface/Tooltips/ChatBubble-Background",
	edgeFile = "Interface/Tooltips/ChatBubble-BackDrop",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 32, right = 32, top = 32, bottom = 32 }
})
MSGTOSRoll.loot_roll_frame:SetBackdropColor(0,0,0, 1)
MSGTOSRoll.loot_roll_frame:SetMovable(true)
MSGTOSRoll.loot_roll_frame:SetClampedToScreen(true)
MSGTOSRoll.loot_roll_frame:SetToplevel(true)
tinsert(UISpecialFrames, MSGTOSRoll.loot_roll_frame:GetName())

MSGTOSRoll.dragger = CreateFrame("Button", nil, MSGTOSRoll.loot_roll_frame)
MSGTOSRoll.dragger:SetPoint("TOPLEFT", MSGTOSRoll.loot_roll_frame, "TOPLEFT", 10,-5)
MSGTOSRoll.dragger:SetPoint("TOPRIGHT", MSGTOSRoll.loot_roll_frame, "TOPRIGHT", -10,-5)
MSGTOSRoll.dragger:SetHeight(8)
MSGTOSRoll.dragger:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
MSGTOSRoll.dragger:SetScript("OnMouseDown", function() MSGTOSRoll.loot_roll_frame:StartMoving() end)
MSGTOSRoll.dragger:SetScript("OnMouseUp", function() MSGTOSRoll.loot_roll_frame:StopMovingOrSizing() end)

MSGTOSRoll.close_button = CreateFrame("Button", "", MSGTOSRoll.loot_roll_frame, "OptionsButtonTemplate")
MSGTOSRoll.close_button:SetText("Close")
MSGTOSRoll.close_button:SetPoint("BOTTOMRIGHT", MSGTOSRoll.loot_roll_frame, "BOTTOMRIGHT", -10, 10)
MSGTOSRoll.close_button:SetScript("OnClick", function() MSGTOSRoll.loot_roll_frame:Hide() end)
MSGTOSRoll.close_button:SetFrameLevel(5)

MSGTOSRoll.next_button = CreateFrame("Button", "", MSGTOSRoll.loot_roll_frame, "OptionsButtonTemplate")
MSGTOSRoll.next_button:SetText("Next >")
MSGTOSRoll.next_button:SetPoint("BOTTOMRIGHT", MSGTOSRoll.close_button, "BOTTOMLEFT", -5, 0)
MSGTOSRoll.next_button:SetScript("OnClick", MSGTOSRoll.show_next_roll)
MSGTOSRoll.next_button:SetFrameLevel(5)
MSGTOSRoll.next_button:Disable()

MSGTOSRoll.prev_button = CreateFrame("Button", "", MSGTOSRoll.loot_roll_frame, "OptionsButtonTemplate")
MSGTOSRoll.prev_button:SetText("< Prev")
MSGTOSRoll.prev_button:SetPoint("BOTTOMRIGHT", MSGTOSRoll.next_button, "BOTTOMLEFT", -5, 0)
MSGTOSRoll.prev_button:SetScript("OnClick", MSGTOSRoll.show_previous_roll)
MSGTOSRoll.prev_button:SetFrameLevel(5)
MSGTOSRoll.prev_button:Disable()

MSGTOSRoll.scroll_frame = CreateFrame("ScrollFrame", "", MSGTOSRoll.loot_roll_frame, "UIPanelScrollFrameTemplate")
MSGTOSRoll.scroll_frame:SetPoint("TOPLEFT", MSGTOSRoll.loot_roll_frame, "TOPLEFT", 20, -20)
MSGTOSRoll.scroll_frame:SetPoint("RIGHT", MSGTOSRoll.loot_roll_frame, "RIGHT", -30, 0)
MSGTOSRoll.scroll_frame:SetPoint("BOTTOM", MSGTOSRoll.close_button, "TOP", 0, 10)

MSGTOSRoll.loot_info = CreateFrame("EditBox", "", MSGTOSRoll.scroll_frame)
MSGTOSRoll.loot_info:SetWidth(450)
MSGTOSRoll.loot_info:SetHeight(485)
MSGTOSRoll.loot_info:SetMultiLine(true)
MSGTOSRoll.loot_info:SetAutoFocus(false)
MSGTOSRoll.loot_info:SetFontObject(GameFontHighlight)
MSGTOSRoll.loot_info:SetScript("OnEditFocusGained", function() MSGTOSRoll.loot_info:ClearFocus() end )

MSGTOSRoll.scroll_frame:SetScrollChild(MSGTOSRoll.loot_info)







MSGTOSRoll.client_roller = CreateFrame("Frame", "MSOSRollerFrame", UIParent)
MSGTOSRoll.client_roller:SetPoint("TOP", "UIParent", "TOP", 0, -225)
MSGTOSRoll.client_roller:SetFrameStrata("TOOLTIP")
MSGTOSRoll.client_roller:SetHeight(180)
MSGTOSRoll.client_roller:SetWidth(240)
MSGTOSRoll.client_roller:SetBackdrop({
	bgFile = "Interface/Tooltips/ChatBubble-Background",
	edgeFile = "Interface/Tooltips/ChatBubble-BackDrop",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 32, right = 32, top = 32, bottom = 32 }
})
MSGTOSRoll.client_roller:SetBackdropColor(0,0,0, 1)
MSGTOSRoll.client_roller:SetMovable(false)
MSGTOSRoll.client_roller:SetClampedToScreen(true)
MSGTOSRoll.client_roller:SetToplevel(true)
MSGTOSRoll.client_roller:Hide()

MSGTOSRoll.client_roller.text = MSGTOSRoll.client_roller:CreateFontString(nil,"ARTWORK") 
MSGTOSRoll.client_roller.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
MSGTOSRoll.client_roller.text:SetPoint("TOP",0,-20)
MSGTOSRoll.client_roller.text:SetText("MS OS Loot Roll")

MSGTOSRoll.client_roller.item_text = MSGTOSRoll.client_roller:CreateFontString(nil,"ARTWORK") 
MSGTOSRoll.client_roller.item_text:SetFont("Fonts\\ARIALN.ttf", 16, "OUTLINE")
MSGTOSRoll.client_roller.item_text:SetPoint("TOP",0,-40)
MSGTOSRoll.client_roller.item_text:SetText("[ITEM LINK HERE]")

MSGTOSRoll.client_roller.ms_button = CreateFrame("Button", "", MSGTOSRoll.client_roller, "OptionsButtonTemplate")
MSGTOSRoll.client_roller.ms_button:SetText("Main Spec")
MSGTOSRoll.client_roller.ms_button:SetPoint("TOPRIGHT", MSGTOSRoll.client_roller, "TOPRIGHT", -20, -70)
MSGTOSRoll.client_roller.ms_button:SetScript("OnClick", function() MSGTOSRoll.make_roll('msroll') end)
MSGTOSRoll.client_roller.ms_button:SetFrameLevel(5)

MSGTOSRoll.client_roller.os_button = CreateFrame("Button", "", MSGTOSRoll.client_roller, "OptionsButtonTemplate")
MSGTOSRoll.client_roller.os_button:SetText("Off Spec")
MSGTOSRoll.client_roller.os_button:SetPoint("TOPRIGHT", MSGTOSRoll.client_roller.ms_button, "BOTTOMRIGHT", 0, -15)
MSGTOSRoll.client_roller.os_button:SetScript("OnClick", function() MSGTOSRoll.make_roll('osroll') end)
MSGTOSRoll.client_roller.os_button:SetFrameLevel(5)

MSGTOSRoll.client_roller.pass_button = CreateFrame("Button", "", MSGTOSRoll.client_roller, "OptionsButtonTemplate")
MSGTOSRoll.client_roller.pass_button:SetText("Pass")
MSGTOSRoll.client_roller.pass_button:SetPoint("TOPRIGHT", MSGTOSRoll.client_roller.os_button, "BOTTOMRIGHT", 0, -15)
MSGTOSRoll.client_roller.pass_button:SetScript("OnClick", function() MSGTOSRoll.make_roll('passes') end)
MSGTOSRoll.client_roller.pass_button:SetFrameLevel(5)

MSGTOSRoll.client_roller.item_icon_frame = CreateFrame("Frame", nil, MSGTOSRoll.client_roller)
MSGTOSRoll.client_roller.item_icon_frame:SetWidth(60)
MSGTOSRoll.client_roller.item_icon_frame:SetHeight(60)
MSGTOSRoll.client_roller.item_icon_frame:SetPoint("TOPLEFT", 40, -70)
MSGTOSRoll.client_roller.item_icon_frame:SetScript("OnEnter", function()
	GameTooltip:SetOwner(MSGTOSRoll.client_roller.item_icon_frame, "ANCHOR_TOP_RIGHT")
	GameTooltip:SetHyperlink(MSGTOSRoll.tool_tip_link)
	GameTooltip:Show()
end)
MSGTOSRoll.client_roller.item_icon_frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

MSGTOSRoll.client_roller.item_icon = MSGTOSRoll.client_roller.item_icon_frame:CreateTexture(nil, "BACKGROUND")
MSGTOSRoll.client_roller.item_icon:SetWidth(60)
MSGTOSRoll.client_roller.item_icon:SetHeight(60)
MSGTOSRoll.client_roller.item_icon:SetPoint("TOPLEFT", 0, 0)
MSGTOSRoll.client_roller.item_icon:SetTexture("Interface\\Icons\\INV_Misc_EngGizmos_17")




local update_roll_window = function(new_roll_data)
    -- If we are not the master looter we need to extract the information into our local cache of the roll
	-- Master looter has already done this when they generated the roll for the user
	-- This also prevents someone from sending the ML a crafted addon message
	if new_roll_data and not MSGTOSRoll.master_looter then
		-- split the new_roll_data on ' ' elements will be user, roll_type, roll
		local roll_data = {}
		for substring in new_roll_data:gmatch("%S+") do
			table.insert(roll_data, substring)
		end
		insert_into_current_tracker(roll_data[2], roll_data[1], roll_data[3])
		generate_roll_text()
	end
	if current_roll_index == nil then
		MSGTOSRoll.loot_info:SetText(MSGTOSRoll.current_roll_text)
		-- MSGTOSRoll.loot_roll_frame:Show()
	end
end


-- This ends a roll for an item, everyone needs to run this so their client knows if a roll ends
MSGTOSRoll.end_roll = function()
	MSGTOSRoll.client_roller:Hide()
	if current_roll_tracker ~= nil then
		table.insert(legacy_rolls, MSGTOSRoll.current_roll_text)
		if MSGTOSRoll.master_looter then
			SendChatMessage("Roll for ".. current_roll_tracker['item_link'] .." has ended", "RAID")
		end
	end
	current_roll_tracker = nil
	roll_opened = false
	already_rolled = false
	if table.getn(legacy_rolls) > 0 then
		MSGTOSRoll.prev_button:Enable()
	end
end

-- This openes up a roll for an item, everyone needs to run this so their client knows if a roll is opened
local start_roll = function(item_link)
	-- Try to pre load the item info. Hopefully this way, later on we can get the texture
	_, _, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(item_link)
	if current_roll_tracker ~= nil then
		MSGTOSRoll.end_roll()
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
	_, _, _, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(item_link)
	MSGTOSRoll.client_roller.item_text:SetText(item_link)
	MSGTOSRoll.client_roller.item_icon:SetTexture(itemTexture)
	MSGTOSRoll.tool_tip_link = item_link
	MSGTOSRoll.client_roller:Show()
	MSGTOSRoll.loot_roll_frame:Show()
end


SLASH_MSGTOSSTARTROLL1 = '/raidroll'
SlashCmdList.MSGTOSSTARTROLL = function(msg, ...)
	if msg == nil then
		addon_variables['send_chat_message']("Please pass an item, end or show")
		return
	end

	if msg == 'show' then
		if MSGTOSRoll.current_roll_text == nil then
			generate_roll_text()
		end
		update_roll_window()
		return
	end

	-- Starting and ending raidrolls can only be done by ML
	if not MSGTOSRoll.master_looter then
		addon_variables['send_chat_message']("You are not the master looter")
		return
	end


	if msg == 'end' then
		if current_roll_tracker == nil then
			addon_variables['send_chat_message']("There is no roll currently opened")
			return
		end
		C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", "end", "RAID")
	else
		if current__roll_tracker ~= nil then
			addon_variables['send_chat_message']("You first need to end the existing roll for")
			return
		end
		local item_name, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(msg)
		if item_name == nil then
			addon_variables['send_chat_message']("Unable to lookup item ".. msg .." did you properly link the item?")
			return
		end

		local item_prio = 'None'
		if addon_variables['prio_list'][item_name] ~= nil then
			item_prio = addon_variables['prio_list'][item_name]
		end
		SendChatMessage("Roll for ".. item_link, "RAID_WARNING")
		SendChatMessage("Prio for ".. item_link ..": ".. item_prio, "RAID")
		C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", "start ".. item_link, "RAID")
	end
end

MSGTOSRoll.make_roll = function(roll_type)
	MSGTOSRoll.client_roller:Hide()
	if not roll_opened then
		addon_variables['send_chat_message']("There is not currently a roll opened")
		return
	end
	if already_rolled then
		addon_variables['send_chat_message']("You have already rolled on this item")
		return
	end
	already_rolled = true
	C_ChatInfo.SendAddonMessage("MSgtOS_ROLL", roll_type .." ".. player_name, "RAID");
end

SLASH_MSGTOSOSROLL1 = '/osroll'
SlashCmdList.MSGTOSOSROLL = function(msg, ...)
	MSGTOSRoll.make_roll('osroll')
end

SLASH_MSGTOSMSROLL1 = '/msroll'
SlashCmdList.MSGTOSMSROLL = function(msg, ...)
	MSGTOSRoll.make_roll('msroll')
end

SLASH_MSGTOSPASSROLL1 = '/pass'
SlashCmdList.MSGTOSPASSROLL = function(msg, ...)
	MSGTOSRoll.make_roll('passes')
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:SetScript("OnEvent", function(self, event, ...)
	if event == "CHAT_MSG_ADDON" then
		local message_type, addon_msg, level = ...
		if message_type == 'MSgtOS_ROLL' then
			if string.sub(addon_msg, 1, 6) == 'start ' then
				start_roll(string.sub(addon_msg, 7))
			elseif addon_msg == 'end' then
				MSGTOSRoll.end_roll()
			elseif string.sub(addon_msg, 1, 11) == 'rollupdate ' then
				update_roll_window(string.sub(addon_msg, 12))
			else
				process_incoming_roll_request(addon_msg)
			end
		end
	elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" then check_if_i_am_master_looter()
	end
end)


C_ChatInfo.RegisterAddonMessagePrefix("MSgtOS_ROLL")
check_if_i_am_master_looter()
