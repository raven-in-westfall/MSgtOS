-- TODO:

local MSgtOS, addon_variables = ...

local player_name = GetUnitName('player')
local missing_cloak = true
local cloak_equiped = false
local _
local back_slot_id
back_slot_id, _ = GetInventorySlotInfo("BackSlot")
local running_check = false
local CloakCheck = {
	results = {
		missing = {},
		needs_equip = {},
		wearing = {},
	},
}
local cloak_name = 'Onyxia Scale Cloak'
local class_colors = {}

local send_chat_message = function(text)
	DEFAULT_CHAT_FRAME:AddMessage("[MS > OS] ".. text, 0.45, 0.0, 1.0)
end

local check_if_i_have_cloak = function()
	missing_cloak = true
	cloak_equiped = false
	local item_name
	-- Check our bags for the cloak
	for bag_id=0, NUM_BAG_SLOTS, 1 do
		for slot_id=0, GetContainerNumSlots(bag_id), 1 do
			local _, _, _, _, _, _, item_link = GetContainerItemInfo(bag_id, slot_id)
			if item_link ~= nil then
				item_name, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(item_link)
				if item_name == cloak_name then
                                    missing_cloak = false
            			end
			end
		end
	end
	-- Check out back slot for the cloak
	local item_link = GetInventoryItemLink("player", back_slot_id)
	if item_link ~= nil then
		item_name, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(item_link)
		if item_name == cloak_name then
			missing_cloak = false
			cloak_equiped = true
		end
	end

	if missing_cloak then
		send_chat_message("YOU DON'T HAVE YOUR ONY CLOAK WITH YOU!")
		C_ChatInfo.SendAddonMessage("MSgtOS_CLOAK", player_name.." missing", "RAID")
	elseif not cloak_equiped then
		C_ChatInfo.SendAddonMessage("MSgtOS_CLOAK", player_name.." needs_equip", "RAID")
	else
		C_ChatInfo.SendAddonMessage("MSgtOS_CLOAK", player_name.." wearing", "RAID")
	end
end

local process_cloak_response = function(message)
        local raid_members = {}
        local raid_colors = {}
        for i = 1, MAX_RAID_MEMBERS do
                user_name, _, _, _, user_class, _, _, _, _, _, _ = GetRaidRosterInfo(i);
                if user_name ~= nil then
                        if class_colors[user_class] == nil then
                                r, g, b, hex = GetClassColor(string.upper(user_class))
                                class_colors[user_class] = hex
                        end
                        raid_members[ user_name ] = true
                        raid_colors[ user_name] = class_colors[user_class]
                end
        end

	-- split the new_roll_data on ' ' elements will be user, roll_type, roll
	local cloak_data = {}
	for substring in message:gmatch("%S+") do
		table.insert(cloak_data, substring)
	end
	user_name = cloak_data[1]
	status = cloak_data[2]
	CloakCheck.results['missing'][user_name] = nil
	CloakCheck.results['needs_equip'][user_name] = nil
	CloakCheck.results['wearing'][user_name] = nil
	CloakCheck.results[status][user_name] = true

	local new_text = '|cffffff00Cloak Check|r\n'
	new_text = new_text ..'\n|cffffff00Missing Cloak|r\n'
	local print_none = true
	for user in pairs(CloakCheck.results['missing']) do
		print_none = false
		new_text = new_text .." |c".. raid_colors[user] .. user .."|r\n"
		raid_members[user] = nil
	end
        if print_none then new_text = new_text .."|cff666666None|r\n" end

	new_text = new_text ..'\n|cffffff00Unequiped|r\n'
	print_none = true
	for user in pairs(CloakCheck.results['needs_equip']) do
		print_none = false
		new_text = new_text .." |c".. raid_colors[user] .. user .."|r\n"
		raid_members[user] = nil
	end
        if print_none then new_text = new_text .."|cff666666None|r\n" end
	
	new_text = new_text ..'\n|cffffff00Ready To Kill|r\n'
	print_none = true
	for user in pairs(CloakCheck.results['wearing']) do
		print_none = false
		new_text = new_text .." |c".. raid_colors[user] .. user .."|r\n"
		raid_members[user] = nil
	end
        if print_none then new_text = new_text .."|cff666666None|r\n" end
	
	new_text = new_text ..'\n|cffffff00Not Reported|r\n'
	print_none = true
	for _, key in ipairs(raid_members) do
		if raid_members[key] ~= nil then
			print_none = false
			new_text = new_text .."|cff666666".. key .."|r\n"
		end
	end
        if print_none then new_text = new_text .."|cff666666None|r\n" end

	CloakCheck.cloak_info:SetText(new_text)
	CloakCheck.top_level_frame:Show()
end

CloakCheck.top_level_frame = CreateFrame("Frame", "CloakCheckFrame", UIParent)
CloakCheck.top_level_frame:Hide()
CloakCheck.top_level_frame:SetPoint("CENTER", "UIParent", "CENTER")
CloakCheck.top_level_frame:SetFrameStrata("TOOLTIP")
CloakCheck.top_level_frame:SetHeight(580)
CloakCheck.top_level_frame:SetWidth(300)
CloakCheck.top_level_frame:SetBackdrop({
	bgFile = "Interface/Tooltips/ChatBubble-Background",
	edgeFile = "Interface/Tooltips/ChatBubble-BackDrop",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 32, right = 32, top = 32, bottom = 32 }
})
CloakCheck.top_level_frame:SetBackdropColor(0,0,0, 1)
CloakCheck.top_level_frame:SetMovable(true)
CloakCheck.top_level_frame:SetClampedToScreen(true)
CloakCheck.top_level_frame:SetToplevel(true)
CloakCheck.top_level_frame:SetScript("OnMouseDown", function() CloakCheck.top_level_frame:StartMoving() end)
CloakCheck.top_level_frame:SetScript("OnMouseUp", function() CloakCheck.top_level_frame:StopMovingOrSizing() end)

local dragger = CreateFrame("Button", nil, CloakCheck.top_level_frame)
dragger:SetPoint("TOPLEFT", CloakCheck.top_level_frame, "TOPLEFT", 10,-5)
dragger:SetPoint("TOPRIGHT", CloakCheck.top_level_frame, "TOPRIGHT", -10,-5)
dragger:SetHeight(8)
dragger:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")

CloakCheck.close_button = CreateFrame("Button", "", CloakCheck.top_level_frame, "OptionsButtonTemplate")
CloakCheck.close_button:SetText("Close")
CloakCheck.close_button:SetPoint("BOTTOMRIGHT", CloakCheck.top_level_frame, "BOTTOMRIGHT", -10, 10)
CloakCheck.close_button:SetScript("OnClick", function() CloakCheck.top_level_frame:Hide() end)
CloakCheck.close_button:SetFrameLevel(5)

CloakCheck.refresh_button = CreateFrame("Button", "", CloakCheck.top_level_frame, "OptionsButtonTemplate")
CloakCheck.refresh_button:SetText("Refresh")
CloakCheck.refresh_button:SetPoint("BOTTOMRIGHT", CloakCheck.close_button, "BOTTOMLEFT", -5, 0)
CloakCheck.refresh_button:SetScript("OnClick", function() C_ChatInfo.SendAddonMessage("MSgtOS_CLOAK", "check", "RAID") end)
CloakCheck.refresh_button:SetFrameLevel(5)

CloakCheck.scroll_frame = CreateFrame("ScrollFrame", "", CloakCheck.top_level_frame, "UIPanelScrollFrameTemplate")
CloakCheck.scroll_frame:SetPoint("TOPLEFT", CloakCheck.top_level_frame, "TOPLEFT", 20, -20)
CloakCheck.scroll_frame:SetPoint("RIGHT", CloakCheck.top_level_frame, "RIGHT", -30, 0)
CloakCheck.scroll_frame:SetPoint("BOTTOM", CloakCheck.close_button, "TOP", 0, 10)

CloakCheck.cloak_info = CreateFrame("EditBox", "", CloakCheck.scroll_frame)
CloakCheck.cloak_info:SetWidth(450)
CloakCheck.cloak_info:SetHeight(485)
CloakCheck.cloak_info:SetMultiLine(true)
CloakCheck.cloak_info:SetAutoFocus(false)
CloakCheck.cloak_info:SetFontObject(GameFontHighlight)
CloakCheck.cloak_info:SetScript("OnEditFocusGained", function() CloakCheck.cloak_info:ClearFocus() end )

CloakCheck.scroll_frame:SetScrollChild(CloakCheck.cloak_info)

SLASH_CLOAKCHECK1 = '/cloak'
SlashCmdList.CLOAKCHECK = function(msg, ...)
	if msg == nil or msg == 'check' then
		running_check = true
		C_ChatInfo.SendAddonMessage("MSgtOS_CLOAK", "check", "RAID")
	elseif msg == 'on' then
		C_ChatInfo.SendAddonMessage("MSgtOS_CLOAK", "on", "RAID")
	else
		send_chat_message("Usage: /cloak [on|check]")
	end
end

CloakCheck.top_level_frame:RegisterEvent("CHAT_MSG_ADDON")
CloakCheck.top_level_frame:SetScript("OnEvent", function(self, event, ...)
	if event == "CHAT_MSG_ADDON" then
		message_type, addon_msg, level = ...
		if message_type == 'MSgtOS_CLOAK' then
                        if addon_msg == "check" then
				check_if_i_have_cloak()
			elseif addon_msg == "on" then
				send_chat_message("Raid master is putting your ".. cloak_name .." on")
				EquipItemByName(cloak_name)
				C_ChatInfo.SendAddonMessage("MSgtOS_CLOAK", "check", "RAID")
			elseif running_check then
				process_cloak_response(addon_msg)
			end
		end
	end
end)


C_ChatInfo.RegisterAddonMessagePrefix("MSgtOS_CLOAK")
