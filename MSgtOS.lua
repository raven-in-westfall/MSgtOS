local MSgtOS, addon_variables = ...

-- local myRoll = random(100)
-- print("Your rolle is " .. myRoll)

local rarity_names = { 'Poor', 'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary' }
local Dialog = LibStub("LibDialog-1.0")
local rarity_threashold = 5
local threashold_exception = {
	['Primal Hakkari Idol'] = true,
	['Light Leather'] = true,
	["Chunk of Boar Meat"] = true
} 
local enable_logging = true
local message_color = {
	['r'] = 0.45,
	['g'] = 0.0,
	['b'] = 1.0,
}
local non_guild_pug_threashold_limit = 1
local current_loot = {}
local group = 'Unknown'

local copy_dialog = Dialog:Register("MSgtOSCopyDialog", {
	text = "Loot Copy\nUse your copy keyboard short cut to copy loot tbale to clipboard",
	width = 500,
	editboxes = {
		{ width = 0,
		  multiline = true,
		  on_escape_pressed = function(self, data) self:GetParent():Hide() end,
		},
	},
	on_show = function(self, data)
		self.editboxes[1]:SetText(data)
		self.editboxes[1]:HighlightText()
		self.editboxes[1]:SetFocus()
	end,
	buttons = {
		{ text = CLOSE, },
	},
	show_while_dead = true,
	hide_on_escape = true,
})

local process_raid_change = function()
	-- validate that we are in a raid and master looter and then turn on logging
	local new_value = false
	local user_raid_index = UnitInRaid("player")
	-- if not ina raid index will be nil
	if user_raid_index then
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo( user_raid_index )
		if isML then
			new_value = true
			-- Determine the Raid Group
			group = 'Ad-Hoc'
			local day = date("%w")
			if day == 6 then
				group = 'Weekend'
			elseif day == 1 or day == 2 then
				group = 'Weekday'
			end
		end
	end
	if enable_logging ~= new_value then
		enable_logging = new_value
		if enable_logging then
			DEFAULT_CHAT_FRAME:AddMessage("[MS > OS] logging enabled for you as loot master", message_color['r'], message_color['g'], message_color['b'])
		else
			DEFAULT_CHAT_FRAME:AddMessage("[MS > OS] logging disabled", message_color["r"], message_color["g"], message_color["b"])
		end
	end

	-- One final check will be to see if anyone in the raid group is not a guild member. If so, this will be considered a pug.
	-- This can't really be done like this because this call only works if the player is within proximity.
	-- Maybe we we can do some kind of 'client' registration.
	-- Where the addon for player X sends the master looter their guild info.
	-- The master looter then collects it to determine if its a PUG.
	--if user_raid_index then
	--	local pug_threashold = non_guild_pug_threashold_limit
	--	for i = 1, MAX_RAID_MEMBERS do
	--		local raid_id = "raid"..i
	--		local player_name = GetUnitName(raid_id)
	--		if player_name then
	--			print("At id ".. i .." got player_name of ".. player_name)
	--			local guild_name, _, _, _ = GetGuildInfo(raid_id)
	--			if guild_name == nil then
	--				guild_name = 'UNGUILDED'
	--			end
	--			print(player_name .." is in guild ".. guild_name)
	--		end
	--	end
	--end
end

local process_loot = function()
	local unit_name = UnitName("target")
	local loot_table = ''
	for i = 1, GetNumLootItems() do
		item_link = GetLootSlotLink(i);
		if item_link ~= nil then
			local item_name, _, item_rarity_number, _, _, _, _, _, _, _, _ = GetItemInfo(item_link)
			local item_rarity = rarity_names[item_rarity_number + 1]
			if item_rarity_number >= rarity_threashold or threashold_exception[item_name] then
				loot_table = loot_table .. date("%m-%d-%y") .. "\t".. GetZoneText() .."\t".. group .."\t\t".. item_name .."\t".. item_rarity .."\t\t\t".. unit_name .."\n"
			end
		end
	end
	if loot_table ~= '' then
		Dialog:Spawn("MSgtOSCopyDialog", loot_table)
	end
end

local process_raid_message = function(message)
	if enable_logging then
		for item_link in message:gmatch("|%x+|Hitem:.-|h.-|h|r") do
			item_name, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(item_link)
			item_prio = 'None'
			if addon_variables['prio_list'][item_name] ~= nil then
				item_prio = addon_variables['prio_list'][item_name]
			end
			SendChatMessage("Prio for ".. item_link ..": ".. item_prio, "RAID")
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("CHAT_MSG_RAID_WARNING");
f:SetScript("OnEvent", function(self, event, ...)
	if event == "LOOT_OPENED" and enable_logging then process_loot()
	elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" then process_raid_change()
	elseif event == "CHAT_MSG_RAID_WARNING" then
		message = ...
		process_raid_message(message)
	end
end)


-- In the case of a reload we want to process_raid_change
process_raid_change()
