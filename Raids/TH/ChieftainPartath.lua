
local module, L = BigWigs:ModuleDeclaration("Chieftain Partath", "Timbermaw Hold")

module.revision = 30137
module.enabletrigger = module.translatedName
module.toggleoptions = {"darkleech", "emeraldnightmare", "eluneswrath", "illuminators", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

L:RegisterTranslations("enUS", function() return {
	cmd = "ChieftainPartath",

	darkleech_cmd = "darkleech",
	darkleech_name = "Dark Leech Alert",
	darkleech_desc = "Warn when a player is afflicted by Dark Leech",

	emeraldnightmare_cmd = "emeraldnightmare",
	emeraldnightmare_name = "Emerald Nightmare Alert",
	emeraldnightmare_desc = "Warn when Chieftain Partath becomes protected by the Emerald Nightmare",

	eluneswrath_cmd = "eluneswrath",
	eluneswrath_name = "Elune's Wrath Alert",
	eluneswrath_desc = "Warn for Elune's Wrath stacks",

	illuminators_cmd = "illuminators",
	illuminators_name = "Illuminators Alert",
	illuminators_desc = "Warn when Withermaw Illuminators cast Rejuvenation",

	trigger_darkLeechYou = "You are afflicted by Dark Leech",--CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_darkLeechOther = "(.+) is afflicted by Dark Leech",--CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE / _PARTY
	msg_darkLeechYou = "Dark Leech on YOU!",
	msg_darkLeechOther = "Dark Leech on %s!",
	bar_darkLeech = " Dark Leech",

	trigger_emeraldNightmare = "becomes protected by the Emerald Nightmare!",--CHAT_MSG_RAID_BOSS_EMOTE
	msg_emeraldNightmare = "Emerald Nightmare - boss is shielded!",
	bar_emeraldNightmare = "Emerald Nightmare",

	trigger_elunesWrath = "Chieftain Partath gains Elune's Wrath %(",--CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS
	msg_elunesWrath = "Elune's Wrath x%d!",

	trigger_darkHarvest = "Chieftain Partath gains Dark Harvest %(",--CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS
	msg_darkHarvest = "Dark Harvest x%d on boss!",

	trigger_illuminatorsRejuv = "Withermaw Illuminators cast Rejuvenation!",--CHAT_MSG_RAID_BOSS_EMOTE
	msg_illuminatorsRejuv = "Illuminators casting Rejuvenation - INTERRUPT!",
} end)

local timer = {
	darkLeech = 10,
	emeraldNightmare = 15,
}
local icon = {
	darkLeech = "Spell_Shadow_LifeDrain02",
	emeraldNightmare = "Spell_Nature_SpiritArmor",
	elunesWrath = "Spell_Nature_StarFall",
	darkHarvest = "Spell_Shadow_GatherShadows",
	illuminators = "Spell_Nature_Rejuvenation",
}
local color = {
	darkLeech = "Red",
	emeraldNightmare = "Cyan",
}
local syncName = {
	darkLeech = "PartathDarkLeech"..module.revision,
	emeraldNightmare = "PartathEmeraldNightmare"..module.revision,
	elunesWrath = "PartathElunesWrath"..module.revision,
	darkHarvest = "PartathDarkHarvest"..module.revision,
	illuminators = "PartathIlluminators"..module.revision,
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")

	self:ThrottleSync(1, syncName.darkLeech)
	self:ThrottleSync(5, syncName.emeraldNightmare)
	self:ThrottleSync(1, syncName.elunesWrath)
	self:ThrottleSync(1, syncName.darkHarvest)
	self:ThrottleSync(5, syncName.illuminators)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
end

function module:OnDisengage()
end

function module:Event(msg)
	if string.find(msg, L["trigger_darkLeechYou"]) then
		self:Sync(syncName.darkLeech .. " " .. UnitName("Player"))

	elseif string.find(msg, L["trigger_darkLeechOther"]) then
		local _, _, player = string.find(msg, L["trigger_darkLeechOther"])
		if player then
			self:Sync(syncName.darkLeech .. " " .. player)
		end

	elseif string.find(msg, L["trigger_emeraldNightmare"]) then
		self:Sync(syncName.emeraldNightmare)

	elseif string.find(msg, L["trigger_elunesWrath"]) then
		local _, _, stacks = string.find(msg, "Elune's Wrath %((%d+)%)")
		if stacks then
			self:Sync(syncName.elunesWrath .. " " .. stacks)
		end

	elseif string.find(msg, L["trigger_darkHarvest"]) then
		local _, _, stacks = string.find(msg, "Dark Harvest %((%d+)%)")
		if stacks then
			self:Sync(syncName.darkHarvest .. " " .. stacks)
		end

	elseif string.find(msg, L["trigger_illuminatorsRejuv"]) then
		self:Sync(syncName.illuminators)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.darkLeech and rest and self.db.profile.darkleech then
		self:DarkLeech(rest)
	elseif sync == syncName.emeraldNightmare and self.db.profile.emeraldnightmare then
		self:EmeraldNightmare()
	elseif sync == syncName.elunesWrath and rest and self.db.profile.eluneswrath then
		self:ElunesWrath(tonumber(rest))
	elseif sync == syncName.darkHarvest and rest and self.db.profile.eluneswrath then
		self:DarkHarvest(tonumber(rest))
	elseif sync == syncName.illuminators and self.db.profile.illuminators then
		self:Illuminators()
	end
end

function module:DarkLeech(player)
	if player == UnitName("Player") then
		self:Message(L["msg_darkLeechYou"], "Urgent", false, nil, false)
		self:Sound("RunAway")
		self:WarningSign(icon.darkLeech, 1)
	else
		self:Message(string.format(L["msg_darkLeechOther"], player), "Attention", false, nil, false)
	end
	self:Bar(player .. L["bar_darkLeech"], timer.darkLeech, icon.darkLeech, true, color.darkLeech)
end

function module:EmeraldNightmare()
	self:Message(L["msg_emeraldNightmare"], "Important", false, nil, false)
	self:Bar(L["bar_emeraldNightmare"], timer.emeraldNightmare, icon.emeraldNightmare, true, color.emeraldNightmare)
	self:Sound("Beware")
	self:WarningSign(icon.emeraldNightmare, 2)
end

function module:ElunesWrath(stacks)
	if stacks then
		self:Message(string.format(L["msg_elunesWrath"], stacks), "Attention", false, nil, false)
		if stacks >= 2 then
			self:WarningSign(icon.elunesWrath, 0.7)
		end
	end
end

function module:DarkHarvest(stacks)
	if stacks then
		self:Message(string.format(L["msg_darkHarvest"], stacks), "Attention", false, nil, false)
	end
end

function module:Illuminators()
	self:Message(L["msg_illuminatorsRejuv"], "Urgent", false, nil, false)
	self:Sound("Alarm")
	self:WarningSign(icon.illuminators, 1)
end
