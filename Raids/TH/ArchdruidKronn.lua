
local module, L = BigWigs:ModuleDeclaration("Archdruid Kronn", "Timbermaw Hold")

module.revision = 30137
module.enabletrigger = module.translatedName
module.toggleoptions = {"nightmareburst", "lucidnightmare", "thornburst", "dreamfever", "intruder", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

L:RegisterTranslations("enUS", function() return {
	cmd = "ArchdruidKronn",

	nightmareburst_cmd = "nightmareburst",
	nightmareburst_name = "Nightmare Burst Alert",
	nightmareburst_desc = "Warn for Nightmare Burst AoE damage",

	lucidnightmare_cmd = "lucidnightmare",
	lucidnightmare_name = "Lucid Nightmare Alert",
	lucidnightmare_desc = "Warn when a player gets Lucid Nightmare",

	thornburst_cmd = "thornburst",
	thornburst_name = "Thorn Burst Alert",
	thornburst_desc = "Warn for Thorn Burst",

	dreamfever_cmd = "dreamfever",
	dreamfever_name = "Dream Fever Alert",
	dreamfever_desc = "Warn for Dream Fever spreading DoT",

	intruder_cmd = "intruder",
	intruder_name = "Intruder of the Dream Alert",
	intruder_desc = "Warn for Intruder of the Dream damage",

	trigger_nightmareBurstHit = "Archdruid Kronn's Nightmare Burst hits",--CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE / _PARTY / _SELF
	msg_nightmareBurst = "Nightmare Burst!",

	trigger_lucidNightmareYou = "You are afflicted by Lucid Nightmare",--CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_lucidNightmareOther = "(.+) is afflicted by Lucid Nightmare",--CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE / _PARTY
	msg_lucidNightmareYou = "Lucid Nightmare on YOU!",
	msg_lucidNightmareOther = "Lucid Nightmare on %s!",
	bar_lucidNightmare = " Lucid Nightmare",

	trigger_thornBurstHit = "Archdruid Kronn's Thorn Burst",--CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE / _PARTY / _SELF
	msg_thornBurst = "Thorn Burst!",

	trigger_dreamFeverYou = "You suffer",--checked below with full pattern
	trigger_dreamFeverOther = "Dream Fever",--checked below with full pattern
	trigger_dreamFeverAfflict = "(.+) is afflicted by Dream Fever",--CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
	msg_dreamFeverYou = "Dream Fever on YOU - spread out!",
	msg_dreamFeverOther = "Dream Fever on %s!",

	trigger_intruderYou = "You suffer",--checked below with full pattern
	trigger_intruderOther = "Intruder of the Dream",--checked below with full pattern
	msg_intruder = "Intruder of the Dream - raid damage!",
} end)

local timer = {
	lucidNightmare = 15,
}
local icon = {
	nightmareBurst = "Spell_Nature_Earthquake",
	lucidNightmare = "Spell_Shadow_ShadowWordPain",
	thornBurst = "Spell_Nature_ThornsWard",
	dreamFever = "Spell_Nature_AbolishMagic",
	intruder = "Spell_Nature_SpiritArmor",
}
local color = {
	lucidNightmare = "Magenta",
}
local syncName = {
	nightmareBurst = "KronnNightmareBurst"..module.revision,
	lucidNightmare = "KronnLucidNightmare"..module.revision,
	thornBurst = "KronnThornBurst"..module.revision,
	dreamFever = "KronnDreamFever"..module.revision,
	intruder = "KronnIntruder"..module.revision,
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")

	self:ThrottleSync(5, syncName.nightmareBurst)
	self:ThrottleSync(1, syncName.lucidNightmare)
	self:ThrottleSync(5, syncName.thornBurst)
	self:ThrottleSync(1, syncName.dreamFever)
	self:ThrottleSync(10, syncName.intruder)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
end

function module:OnDisengage()
end

function module:Event(msg)
	if string.find(msg, L["trigger_nightmareBurstHit"]) then
		self:Sync(syncName.nightmareBurst)

	elseif string.find(msg, L["trigger_lucidNightmareYou"]) and string.find(msg, "Lucid Nightmare") then
		self:Sync(syncName.lucidNightmare .. " " .. UnitName("Player"))
	elseif string.find(msg, L["trigger_lucidNightmareOther"]) then
		local _, _, player = string.find(msg, L["trigger_lucidNightmareOther"])
		if player then
			self:Sync(syncName.lucidNightmare .. " " .. player)
		end

	elseif string.find(msg, L["trigger_thornBurstHit"]) then
		self:Sync(syncName.thornBurst)

	elseif string.find(msg, "Dream Fever") then
		if string.find(msg, L["trigger_dreamFeverAfflict"]) then
			local _, _, player = string.find(msg, L["trigger_dreamFeverAfflict"])
			if player then
				self:Sync(syncName.dreamFever .. " " .. player)
			end
		elseif string.find(msg, "You are afflicted by Dream Fever") then
			self:Sync(syncName.dreamFever .. " " .. UnitName("Player"))
		end

	elseif string.find(msg, "Intruder of the Dream") then
		self:Sync(syncName.intruder)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.nightmareBurst and self.db.profile.nightmareburst then
		self:NightmareBurst()
	elseif sync == syncName.lucidNightmare and rest and self.db.profile.lucidnightmare then
		self:LucidNightmare(rest)
	elseif sync == syncName.thornBurst and self.db.profile.thornburst then
		self:ThornBurst()
	elseif sync == syncName.dreamFever and rest and self.db.profile.dreamfever then
		self:DreamFever(rest)
	elseif sync == syncName.intruder and self.db.profile.intruder then
		self:Intruder()
	end
end

function module:NightmareBurst()
	self:Message(L["msg_nightmareBurst"], "Urgent", false, nil, false)
	self:WarningSign(icon.nightmareBurst, 0.7)
	self:Sound("Beware")
end

function module:LucidNightmare(player)
	if player == UnitName("Player") then
		self:Message(L["msg_lucidNightmareYou"], "Urgent", false, nil, false)
		self:Sound("RunAway")
		self:WarningSign(icon.lucidNightmare, 1)
	else
		self:Message(string.format(L["msg_lucidNightmareOther"], player), "Attention", false, nil, false)
	end
	self:Bar(player .. L["bar_lucidNightmare"], timer.lucidNightmare, icon.lucidNightmare, true, color.lucidNightmare)
end

function module:ThornBurst()
	self:Message(L["msg_thornBurst"], "Attention", false, nil, false)
end

function module:DreamFever(player)
	if player == UnitName("Player") then
		self:Message(L["msg_dreamFeverYou"], "Urgent", false, nil, false)
		self:Sound("RunAway")
		self:WarningSign(icon.dreamFever, 1)
	else
		self:Message(string.format(L["msg_dreamFeverOther"], player), "Attention", false, nil, false)
	end
end

function module:Intruder()
	self:Message(L["msg_intruder"], "Attention", false, nil, false)
end
