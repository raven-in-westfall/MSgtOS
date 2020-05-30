local MSgtOS, addon_variables = ...

addon_variables['prio_list']['Chunk of Boar Meat'] = 'The looser'
GameTooltip:HookScript("OnTooltipSetItem", function(self, ...) 
	GameTooltip:AddLine("Prio List:")
	item_name, item_link = GameTooltip:GetItem()
	if addon_variables['prio_list'][item_name] == nil then
		GameTooltip:AddLine("  None")
	else
		GameTooltip:AddLine("    ".. addon_variables['prio_list'][item_name])
	end
end)

-- GameToolTip:SetScript("OnClick", function(self, button)
-- 	print("Clicked")
-- end)
