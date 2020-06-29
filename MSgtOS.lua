-- TODO:
--	Can we auto-close copy window on ctl-c pressed?
--	Don't log elementum ore

local MSgtOS, addon_variables = ...

local rarity_names = { 'Poor', 'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary' }
local Dialog = LibStub("LibDialog-1.0")
local rarity_threashold = 4
local threashold_exception = {
	['Primal Hakkari Idol'] = true,
} 
local ignore_items = {
	['Elementium Ore'] = true,
	["Chunk of Boar Meat"] = true,
}
addon_variables['send_chat_message'] = function(text)
        DEFAULT_CHAT_FRAME:AddMessage("[MS > OS] ".. text, 0.45, 0.0, 1.0)
end

local enable_logging = true
local non_guild_pug_threashold_limit = 1
local current_loot = {}
local raid_group = nil
local player_name = GetUnitName('player')

local addon_checks = {}
addon_checks[player_name] = true

local check_addons = function()
        if is_master_looter then
        end
end

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
		end
	end
	if enable_logging ~= new_value then
		enable_logging = new_value
		if enable_logging then
			addon_variables['send_chat_message']('logging enabled for you as loot master')
		else
			addon_variables['send_chat_message']('logging disabled')
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

	check_addons()
end

local process_loot = function()
	local unit_name = UnitName("target")
	local loot_table = ''
        if raid_group == nil then
                -- Determine the Raid Group
                raid_group = 'Ad-Hoc'
                local day = date("%w")
                if day == "6" then
                        raid_group = 'Weekend'
                elseif day == "1" or day == "2" then
                        raid_group = 'Weekday'
                end
        end
	for i = 1, GetNumLootItems() do
		item_link = GetLootSlotLink(i);
		if item_link ~= nil then
			local item_name, _, item_rarity_number, _, _, _, _, _, _, _, _ = GetItemInfo(item_link)
			if not ignore_items[item_name] then
				local item_rarity = rarity_names[item_rarity_number + 1]
                        	local zone = GetZoneText()
                        	if zone == 'The Molten Core' then
                                	zone = 'MC'
				elseif zone == 'Blackwing Lair' then
					zone = 'BWL'
				elseif zone == "Onyxia's Lair" then
					zone = 'Ony'
				elseif zone == "Zul'gurub" then
					zone = 'ZG'
                        	end
				if item_rarity_number >= rarity_threashold or threashold_exception[item_name] then
					loot_table = loot_table .. date("%m-%d-%y") .. "\t".. GetZoneText() .."\t".. raid_group .."\t\t".. item_name .."\t".. item_rarity .."\t0\t0\t".. unit_name .."\n"
				end
			end
		end
	end
	if loot_table ~= '' then
		Dialog:Spawn("MSgtOSCopyDialog", loot_table)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function(self, event, ...)
	if event == "LOOT_OPENED" and enable_logging then process_loot()
	elseif event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" then process_raid_change()
	end
end)

-- In the case of a reload we want to process_raid_change
process_raid_change()
