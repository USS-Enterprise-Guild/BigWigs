
local module, L = BigWigs:ModuleDeclaration("Karrsh the Sentinel", "Timbermaw Hold")

module.revision = 30137
module.enabletrigger = module.translatedName
module.toggleoptions = {"crushingmaul", "furiousroar", "felstomp", "seedofcorruption", "demonwithin", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

L:RegisterTranslations("enUS", function() return {
	cmd = "KarrshTheSentinel",

	crushingmaul_cmd = "crushingmaul",
	crushingmaul_name = "Crushing Maul Alert",
	crushingmaul_desc = "Warn when Karrsh begins casting Crushing Maul",

	furiousroar_cmd = "furiousroar",
	furiousroar_name = "Furious Roar Alert",
	furiousroar_desc = "Warn for Furious Roar AoE",

	felstomp_cmd = "felstomp",
	felstomp_name = "Fel Stomp Alert",
	felstomp_desc = "Warn when Karrsh begins casting Fel Stomp",

	seedofcorruption_cmd = "seedofcorruption",
	seedofcorruption_name = "Seed of Corruption Alert",
	seedofcorruption_desc = "Warn for Seed of Corruption explosion",

	demonwithin_cmd = "demonwithin",
	demonwithin_name = "Demon Within Alert",
	demonwithin_desc = "Warn for Demon Within stacks and phase transition",

	trigger_crushingMaulCast = "Karrsh the Sentinel begins to cast Crushing Maul.",--CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	msg_crushingMaul = "Crushing Maul incoming - tank swap or cooldown!",
	bar_crushingMaul = "Crushing Maul",

	trigger_furiousRoar = "Karrsh the Sentinel's Furious Roar hits",--CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE / _SELF_DAMAGE / _CREATURE_DAMAGE
	trigger_furiousRoarImmune = "Karrsh the Sentinel's Furious Roar fails.",--CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	msg_furiousRoar = "Furious Roar!",

	trigger_felStompCast = "Karrsh the Sentinel begins to perform Fel Stomp.",--CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	msg_felStomp = "Fel Stomp - move away!",
	bar_felStomp = "Fel Stomp",

	trigger_seedHit = "Karrsh the Sentinel's Seed of Corruption hits",--CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	msg_seed = "Seed of Corruption exploded!",

	trigger_demonWithin = "Karrsh the Sentinel gains Demon Within %(",--CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS
	trigger_demonWithinYell = "My flesh\226\128\166 my soul\226\128\166 ALL FOR THE DEMON WITHIN!",--CHAT_MSG_MONSTER_YELL
	msg_demonWithinStack = "Demon Within x%d!",
	msg_demonWithinPhase = "DEMON WITHIN - Phase 2!",
} end)

local timer = {
	crushingMaul = 2,
	felStomp = 2,
}
local icon = {
	crushingMaul = "Ability_Warrior_Decisivestrike",
	furiousRoar = "Ability_Druid_ChallangingRoar",
	felStomp = "Spell_Nature_Earthquake",
	seed = "Spell_Shadow_SeedOfDestruction",
	demonWithin = "Spell_Shadow_DemonForm",
}
local color = {
	crushingMaul = "Red",
	felStomp = "Yellow",
}
local syncName = {
	crushingMaul = "KarrshCrushingMaul"..module.revision,
	furiousRoar = "KarrshFuriousRoar"..module.revision,
	felStomp = "KarrshFelStomp"..module.revision,
	seed = "KarrshSeed"..module.revision,
	demonWithin = "KarrshDemonWithin"..module.revision,
	demonWithinPhase = "KarrshDemonWithinPhase"..module.revision,
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	self:ThrottleSync(3, syncName.crushingMaul)
	self:ThrottleSync(3, syncName.furiousRoar)
	self:ThrottleSync(3, syncName.felStomp)
	self:ThrottleSync(5, syncName.seed)
	self:ThrottleSync(1, syncName.demonWithin)
	self:ThrottleSync(5, syncName.demonWithinPhase)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
end

function module:OnDisengage()
end

function module:CHAT_MSG_MONSTER_YELL(msg, sender)
	if msg == L["trigger_demonWithinYell"] then
		self:Sync(syncName.demonWithinPhase)
	end
end

function module:Event(msg)
	if string.find(msg, L["trigger_crushingMaulCast"]) then
		self:Sync(syncName.crushingMaul)

	elseif string.find(msg, L["trigger_furiousRoar"]) or string.find(msg, L["trigger_furiousRoarImmune"]) then
		self:Sync(syncName.furiousRoar)

	elseif string.find(msg, L["trigger_felStompCast"]) then
		self:Sync(syncName.felStomp)

	elseif string.find(msg, L["trigger_seedHit"]) then
		self:Sync(syncName.seed)

	elseif string.find(msg, L["trigger_demonWithin"]) then
		local _, _, stacks = string.find(msg, "Demon Within %((%d+)%)")
		if stacks then
			self:Sync(syncName.demonWithin .. " " .. stacks)
		end
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.crushingMaul and self.db.profile.crushingmaul then
		self:CrushingMaul()
	elseif sync == syncName.furiousRoar and self.db.profile.furiousroar then
		self:FuriousRoar()
	elseif sync == syncName.felStomp and self.db.profile.felstomp then
		self:FelStomp()
	elseif sync == syncName.seed and self.db.profile.seedofcorruption then
		self:Seed()
	elseif sync == syncName.demonWithin and rest and self.db.profile.demonwithin then
		self:DemonWithin(tonumber(rest))
	elseif sync == syncName.demonWithinPhase and self.db.profile.demonwithin then
		self:DemonWithinPhase()
	end
end

function module:CrushingMaul()
	self:Message(L["msg_crushingMaul"], "Urgent", false, nil, false)
	self:Bar(L["bar_crushingMaul"], timer.crushingMaul, icon.crushingMaul, true, color.crushingMaul)
	self:Sound("Beware")
end

function module:FuriousRoar()
	self:Message(L["msg_furiousRoar"], "Attention", false, nil, false)
	self:WarningSign(icon.furiousRoar, 0.7)
end

function module:FelStomp()
	self:Message(L["msg_felStomp"], "Urgent", false, nil, false)
	self:Bar(L["bar_felStomp"], timer.felStomp, icon.felStomp, true, color.felStomp)
	self:Sound("Alarm")
end

function module:Seed()
	self:Message(L["msg_seed"], "Attention", false, nil, false)
	self:WarningSign(icon.seed, 0.7)
end

function module:DemonWithin(stacks)
	if stacks then
		self:Message(string.format(L["msg_demonWithinStack"], stacks), "Attention", false, nil, false)
		if stacks >= 10 then
			self:WarningSign(icon.demonWithin, 0.7)
		end
	end
end

function module:DemonWithinPhase()
	self:Message(L["msg_demonWithinPhase"], "Important", false, nil, false)
	self:Sound("Beware")
	self:WarningSign(icon.demonWithin, 2)
end
