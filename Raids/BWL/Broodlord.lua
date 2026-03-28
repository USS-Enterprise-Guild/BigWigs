
local module, L = BigWigs:ModuleDeclaration("Broodlord Lashlayer", "Blackwing Lair")

module.revision = 3008617011
module.enabletrigger = module.translatedName
module.toggleoptions = {"ms", "bw", "knock", "serratedwound", -1, "targeticon", "bosskill"}

L:RegisterTranslations("enUS", function() return {
	cmd = "Broodlord",
	
	ms_cmd = "ms",
	ms_name = "Mortal Strike Alert",
	ms_desc = "Warn for Mortal Strike",

	bw_cmd = "bw",
	bw_name = "Blast Wave Alert",
	bw_desc = "Warn for Blast Wave",
	
	knock_cmd = "knock",
	knock_name = "Knock Away Alert",
	knock_desc = "Warn for Knock Away",
	
	serratedwound_cmd = "serratedwound",
	serratedwound_name = "Serrated Wound Alert",
	serratedwound_desc = "Warn for Serrated Wound bleed DoT",

	targeticon_cmd = "targeticon",
	targeticon_name = "Skull Icon on Bloodlord's Target",
	targeticon_desc = "Put a Skull Raid Icon on Bloodlord's Target",
	
	
	trigger_engage = "None of your kind should be here! You've doomed only yourselves!",
	
	trigger_msEvade = "Broodlord Lashlayer's Mortal Strike was", --CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE // CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE // CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	msg_msEvade = "Mortal Strike was Dodged!",
	
	trigger_msYou = "You are afflicted by Mortal Strike.", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_msOther = "(.+) is afflicted by Mortal Strike.", --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
	trigger_msFade = "Mortal Strike fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
	bar_msCd = "Mortal Strike CD",
	bar_msSoon = "Mortal Strike Soon...",
	bar_msDur = " Mortal Strike",
	msg_ms = " Mortal Strike",
	
	trigger_bw = "Broodlord Lashlayer's Blast Wave", --CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE // CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE // CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	bar_bwCd = "Blast Wave CD",
	bar_bwSoon = "Blast Wave Soon...",
	
	trigger_knock = "Broodlord Lashlayer's Knock Away", --CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE // CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE // CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	bar_knockCd = "Knock Away CD",
	bar_knockSoon = "Knock Away Soon...",

	trigger_serratedWoundYou = "You are afflicted by Serrated Wound", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_serratedWoundOther = "(.+) is afflicted by Serrated Wound", --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
	trigger_serratedWoundFade = "Serrated Wound fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
	bar_serratedWound = " Serrated Wound",
	msg_serratedWound = " Serrated Wound - Heal through!",
} end )

local timer = {
	msFirstCd = 48,--first supposed to be 25, saw 48!?
	msCd = 20,--cd supposed to be {20,30}, saw 26, 27
	msSoon = 10,
	msDur = 5,
	
	bwCd = 20,--first is 20, next are 20 minimum
	bwSoon = 15,--20+15=35, saw 29, 25, 31, supposed to be {20,35}
	
	knockFirstCd = 20,
	knockFirstSoon = 5,
	knockCd = 12,--first is 20-25, next are 12,25
	knockSoon = 13,

	serratedWound = 6,
}
local icon = {
	ms = "Ability_Warrior_SavageBlow",
	bw = "Spell_Holy_Excorcism_02",
	knock = "INV_Gauntlets_05",
	serratedWound = "ability_rogue_rupture",
}
local color = {
	msCd = "Black",
	msSoon = "Black",
	msDur = "Magenta",
	
	bwCd = "Orange",
	bwSoon = "Red",
	
	knockCd = "Cyan",
	knockSoon = "Blue",

	serratedWound = "Red",
}
local syncName = {
	ms = "BroodlordMs"..module.revision,
	msFade = "BroodlordMsFade"..module.revision,
	bw = "BroodlordBlastWave"..module.revision,
	knock = "BroodlordKnockAway"..module.revision,
	serratedWound = "BroodlordSerratedWound"..module.revision,
	serratedWoundFade = "BroodlordSerratedWoundFade"..module.revision,
}

-- Backward compat: accept syncs from any older revision
local syncBases = {}
do
	local revLen = string.len(tostring(module.revision))
	for k, v in pairs(syncName) do
		syncBases[string.sub(v, 1, string.len(v) - revLen)] = v
	end
end
local function translateSync(sync)
	for base, currentName in pairs(syncBases) do
		if string.sub(sync, 1, string.len(base)) == base then
			local rev = tonumber(string.sub(sync, string.len(base) + 1))
			if rev and rev < module.revision then
				return currentName
			end
		end
	end
	return sync
end

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
	--self:RegisterEvent("CHAT_MSG_SAY", "Event") --Debug
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") --trigger_msYou
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") --trigger_msOther
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") --trigger_msOther
	
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event") --trigger_msFade
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event") --trigger_msFade
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event") --trigger_msFade
	
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event") --trigger_bw, trigger_knock, trigger_msEvade
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "Event") --trigger_bw, trigger_knock, trigger_msEvade
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event") --trigger_bw, trigger_knock, trigger_msEvade
	
	
	self:ThrottleSync(3, syncName.ms)
	self:ThrottleSync(3, syncName.msFade)
	self:ThrottleSync(3, syncName.bw)
	self:ThrottleSync(3, syncName.knock)
	self:ThrottleSync(3, syncName.serratedWound)
	self:ThrottleSync(3, syncName.serratedWoundFade)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
	if self.db.profile.ms then
		self:Bar(L["bar_msCd"], timer.msFirstCd, icon.ms, true, color.msCd)
	end
	
	if self.db.profile.bw then
		self:Bar(L["bar_bwCd"], timer.bwCd, icon.bw, true, color.bwCd)
	end
	
	if self.db.profile.knock then
		self:Bar(L["bar_knockCd"], timer.knockFirstCd, icon.knock, true, color.knockCd)
		self:DelayedBar(timer.knockFirstCd, L["bar_knockSoon"], timer.knockFirstSoon, icon.knock, true, color.knockSoon)
	end
	
	if self.db.profile.targeticon then
		self:ScheduleRepeatingEvent("BroodlordTargetCheck", self.BroodlordTarget, 0.5, self)
	end
end

function module:OnDisengage()
	self:CancelScheduledEvent("BroodlordTargetCheck")
end

function module:BroodlordTarget()
	if UnitName("Target") ~= nil and UnitName("TargetTarget") ~= nil and (IsRaidLeader() or IsRaidOfficer()) then
		if UnitName("Target") == "Broodlord Lashlayer" then
			SetRaidTarget("TargetTarget",8)
		end
	end
end

function module:Event(msg)
	if msg == L["trigger_msYou"] then
		self:Sync(syncName.ms .. " "..UnitName("player"))
	
	elseif string.find(msg, L["trigger_msOther"]) then
		local _,_,msPerson, _ = string.find(msg, L["trigger_msOther"])
		self:Sync(syncName.ms .. " "..msPerson)
	
	elseif string.find(msg, L["trigger_msFade"]) then
		local _,_,msFadePerson, _ = string.find(msg, L["trigger_msFade"])
		if msFadePerson == "you" then msFadePerson = UnitName("Player") end
		self:Sync(syncName.msFade .. " "..msFadePerson)
		
	elseif string.find(msg, L["trigger_msEvade"]) then
		self:Sync(syncName.ms .. " ".."msEvade")
	

	elseif string.find(msg, L["trigger_bw"]) then
		self:Sync(syncName.bw)
		
	elseif string.find(msg, L["trigger_knock"]) then
		self:Sync(syncName.knock)

	elseif msg == L["trigger_serratedWoundYou"] then
		self:Sync(syncName.serratedWound .. " " .. UnitName("Player"))

	elseif string.find(msg, L["trigger_serratedWoundOther"]) then
		local _,_,swPlayer,_ = string.find(msg, L["trigger_serratedWoundOther"])
		self:Sync(syncName.serratedWound .. " " .. swPlayer)

	elseif string.find(msg, L["trigger_serratedWoundFade"]) then
		local _,_,swFadePlayer,_ = string.find(msg, L["trigger_serratedWoundFade"])
		if swFadePlayer == "you" then swFadePlayer = UnitName("Player") end
		self:Sync(syncName.serratedWoundFade .. " " .. swFadePlayer)
	end
end


function module:BigWigs_RecvSync(sync, rest, nick)
	sync = translateSync(sync)

	if sync == syncName.ms and rest and self.db.profile.ms then
		if rest ~= "msEvade" then rest = self:ValidatePlayerSync(rest, sync, nick) end
		if rest then self:Ms(rest) end
	elseif sync == syncName.msFade and rest and self.db.profile.ms then
		rest = self:ValidatePlayerSync(rest, sync, nick)
		if rest then self:MsFade(rest) end

	elseif sync == syncName.bw and self.db.profile.bw then
		self:BW()

	elseif sync == syncName.knock and self.db.profile.knock then
		self:Knock()

	elseif sync == syncName.serratedWound and rest and self.db.profile.serratedwound then
		rest = self:ValidatePlayerSync(rest, sync, nick)
		if rest then self:SerratedWound(rest) end
	elseif sync == syncName.serratedWoundFade and rest and self.db.profile.serratedwound then
		rest = self:ValidatePlayerSync(rest, sync, nick)
		if rest then self:SerratedWoundFade(rest) end
	end
end


function module:Ms(rest)
	self:CancelDelayedBar(L["bar_msSoon"])
	self:RemoveBar(L["bar_msSoon"])
	self:RemoveBar(L["bar_msCd"])
	
	if rest ~= "msEvade" then
		self:Bar(rest..L["bar_msDur"], timer.msDur, icon.ms, true, color.msDur)
		self:Message(rest..L["msg_ms"], "Urgent", false, nil, false)
	
		self:DelayedBar(timer.msDur, L["bar_msCd"], timer.msCd, icon.ms, true, color.msCd)
		self:DelayedBar(timer.msDur + timer.msCd, L["bar_msSoon"], timer.msSoon, icon.ms, true, color.msSoon)
	else
		self:Message(L["msg_msEvade"], "Urgent", false, nil, false)
	
		self:Bar(L["bar_msCd"], timer.msDur + timer.msCd, icon.ms, true, color.msCd)
		self:DelayedBar(timer.msDur + timer.msCd, L["bar_msSoon"], timer.msSoon, icon.ms, true, color.msSoon)
	end
end

function module:MsFade(rest)
	self:RemoveBar(rest..L["bar_msDur"])
end

function module:BW()
	self:CancelDelayedBar(L["bar_bwSoon"])
	self:RemoveBar(L["bar_bwSoon"])
	
	self:Bar(L["bar_bwCd"], timer.bwCd, icon.bw, true, color.bwCd)
	self:DelayedBar(timer.bwCd, L["bar_bwSoon"], timer.bwSoon, icon.bw, true, color.bwSoon)
end

function module:Knock()
	self:CancelDelayedBar(L["bar_knockSoon"])
	self:RemoveBar(L["bar_knockSoon"])

	self:Bar(L["bar_knockCd"], timer.knockCd, icon.knock, true, color.knockCd)
	self:DelayedBar(timer.knockCd, L["bar_knockSoon"], timer.knockSoon, icon.knock, true, color.knockSoon)
end

function module:SerratedWound(rest)
	self:Bar(rest..L["bar_serratedWound"], timer.serratedWound, icon.serratedWound, true, color.serratedWound)
	self:Message(rest..L["msg_serratedWound"], "Important", false, nil, false)
end

function module:SerratedWoundFade(rest)
	self:RemoveBar(rest..L["bar_serratedWound"])
end
