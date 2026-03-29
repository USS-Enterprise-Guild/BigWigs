
local module, L = BigWigs:ModuleDeclaration("Rotgrowl", "Timbermaw Hold")

module.revision = 30137
module.enabletrigger = module.translatedName
module.toggleoptions = {"firesoakedarrow", "untamedfire", "fearfulroar", "huntersmark", "volleyofarrows", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Rotgrowl",

	firesoakedarrow_cmd = "firesoakedarrow",
	firesoakedarrow_name = "Fire-Soaked Arrow Alert",
	firesoakedarrow_desc = "Warn for Fire-Soaked Arrow",

	untamedfire_cmd = "untamedfire",
	untamedfire_name = "Untamed Fire Alert",
	untamedfire_desc = "Warn for Untamed Fire AoE",

	fearfulroar_cmd = "fearfulroar",
	fearfulroar_name = "Fearful Roar Alert",
	fearfulroar_desc = "Warn for Fearful Roar fear",

	huntersmark_cmd = "huntersmark",
	huntersmark_name = "Hunter's Mark Alert",
	huntersmark_desc = "Warn when a player gets Hunter's Mark",

	volleyofarrows_cmd = "volleyofarrows",
	volleyofarrows_name = "Volley of Arrows Alert",
	volleyofarrows_desc = "Warn for Volley of Arrows",

	trigger_fireSoakedArrowHit = "Rotgrowl's Fire%-Soaked Arrow hits",--CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE / _PARTY / _SELF
	msg_fireSoakedArrow = "Fire-Soaked Arrow!",

	trigger_untamedFireHit = "Rotgrowl's Untamed Fire hits",--CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE / _PARTY / _SELF
	msg_untamedFire = "Untamed Fire!",

	trigger_fearfulRoarYou = "You are afflicted by Fearful Roar",--CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_fearfulRoarOther = "is afflicted by Fearful Roar",--CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE / _PARTY
	msg_fearfulRoar = "Fearful Roar - feared!",
	bar_fearfulRoar = "Fearful Roar",

	trigger_huntersMarkYou = "You are afflicted by Hunter's Mark",--CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_huntersMarkOther = "(.+) is afflicted by Hunter's Mark",--CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE / _PARTY
	msg_huntersMarkYou = "Hunter's Mark on YOU!",
	msg_huntersMarkOther = "Hunter's Mark on %s!",
	bar_huntersMark = " Hunter's Mark",

	trigger_volleyYou = "You are afflicted by Volley of Arrows",--CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_volleyOther = "(.+) is afflicted by Volley of Arrows",--CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE / _PARTY
	msg_volleyYou = "Volley of Arrows on YOU - move!",
	msg_volleyOther = "Volley of Arrows on %s!",
} end)

local timer = {
	fearfulRoar = 6,
	huntersMark = 15,
}
local icon = {
	fireSoakedArrow = "Ability_Searingarrow",
	untamedFire = "Spell_Fire_Incinerate",
	fearfulRoar = "Ability_Druid_ChallangingRoar",
	huntersMark = "Ability_Hunter_SniperShot",
	volley = "Ability_Marksmanship",
}
local color = {
	fireSoakedArrow = "Red",
	fearfulRoar = "Yellow",
	huntersMark = "Magenta",
}
local syncName = {
	fireSoakedArrow = "RotgrowlFireSoakedArrow"..module.revision,
	untamedFire = "RotgrowlUntamedFire"..module.revision,
	fearfulRoar = "RotgrowlFearfulRoar"..module.revision,
	huntersMark = "RotgrowlHuntersMark"..module.revision,
	volley = "RotgrowlVolley"..module.revision,
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")

	self:ThrottleSync(3, syncName.fireSoakedArrow)
	self:ThrottleSync(3, syncName.untamedFire)
	self:ThrottleSync(3, syncName.fearfulRoar)
	self:ThrottleSync(1, syncName.huntersMark)
	self:ThrottleSync(1, syncName.volley)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
end

function module:OnDisengage()
end

function module:Event(msg)
	if string.find(msg, L["trigger_fireSoakedArrowHit"]) then
		self:Sync(syncName.fireSoakedArrow)

	elseif string.find(msg, L["trigger_untamedFireHit"]) then
		self:Sync(syncName.untamedFire)

	elseif string.find(msg, L["trigger_fearfulRoarYou"]) then
		self:Sync(syncName.fearfulRoar)
	elseif string.find(msg, L["trigger_fearfulRoarOther"]) then
		self:Sync(syncName.fearfulRoar)

	elseif string.find(msg, L["trigger_huntersMarkYou"]) then
		self:Sync(syncName.huntersMark .. " " .. UnitName("Player"))
	elseif string.find(msg, L["trigger_huntersMarkOther"]) then
		local _, _, player = string.find(msg, L["trigger_huntersMarkOther"])
		if player then
			self:Sync(syncName.huntersMark .. " " .. player)
		end

	elseif string.find(msg, L["trigger_volleyYou"]) then
		self:Sync(syncName.volley .. " " .. UnitName("Player"))
	elseif string.find(msg, L["trigger_volleyOther"]) then
		local _, _, player = string.find(msg, L["trigger_volleyOther"])
		if player then
			self:Sync(syncName.volley .. " " .. player)
		end
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.fireSoakedArrow and self.db.profile.firesoakedarrow then
		self:FireSoakedArrow()
	elseif sync == syncName.untamedFire and self.db.profile.untamedfire then
		self:UntamedFire()
	elseif sync == syncName.fearfulRoar and self.db.profile.fearfulroar then
		self:FearfulRoar()
	elseif sync == syncName.huntersMark and rest and self.db.profile.huntersmark then
		self:HuntersMark(rest)
	elseif sync == syncName.volley and rest and self.db.profile.volleyofarrows then
		self:Volley(rest)
	end
end

function module:FireSoakedArrow()
	self:Message(L["msg_fireSoakedArrow"], "Urgent", false, nil, false)
	self:WarningSign(icon.fireSoakedArrow, 0.7)
	self:Sound("Beware")
end

function module:UntamedFire()
	self:Message(L["msg_untamedFire"], "Attention", false, nil, false)
end

function module:FearfulRoar()
	self:Message(L["msg_fearfulRoar"], "Urgent", false, nil, false)
	self:Bar(L["bar_fearfulRoar"], timer.fearfulRoar, icon.fearfulRoar, true, color.fearfulRoar)
	self:WarningSign(icon.fearfulRoar, 0.7)
end

function module:HuntersMark(player)
	if player == UnitName("Player") then
		self:Message(L["msg_huntersMarkYou"], "Urgent", false, nil, false)
		self:Sound("RunAway")
		self:WarningSign(icon.huntersMark, 1)
	else
		self:Message(string.format(L["msg_huntersMarkOther"], player), "Attention", false, nil, false)
	end
	self:Bar(player .. L["bar_huntersMark"], timer.huntersMark, icon.huntersMark, true, color.huntersMark)
end

function module:Volley(player)
	if player == UnitName("Player") then
		self:Message(L["msg_volleyYou"], "Urgent", false, nil, false)
		self:Sound("RunAway")
		self:WarningSign(icon.volley, 1)
	else
		self:Message(string.format(L["msg_volleyOther"], player), "Attention", false, nil, false)
	end
end
