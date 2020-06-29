-- TODO:
--   Make the /prio only work for ML

local MSgtOS, addon_variables = ...

GameTooltip:HookScript("OnTooltipSetItem", function(self, ...) 
	GameTooltip:AddLine("Prio List:")
	item_name, item_link = GameTooltip:GetItem()
	if addon_variables['prio_list'][item_name] == nil then
		GameTooltip:AddLine("  None")
	else
		GameTooltip:AddLine("    ".. addon_variables['prio_list'][item_name])
	end
end)

SLASH_PRIO1 = '/prio'
SlashCmdList.PRIO = function(msg, ...)
	if msg == nil then
		addon_variables['send_chat_message']("Please pass an item")
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
	if addon_variables['is_master_looter'] then
		SendChatMessage("Prio for ".. msg ..": ".. item_prio, "RAID")
	else
		addon_variables['send_chat_message']("Prio for ".. msg ..": ".. item_prio)
	end
end

-- GameToolTip:SetScript("OnClick", function(self, button)
-- 	print("Clicked")
-- end)


