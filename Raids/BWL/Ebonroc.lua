
local module, L = BigWigs:ModuleDeclaration("Ebonroc", "Blackwing Lair")

module.revision = 3008617011
module.enabletrigger = module.translatedName
module.toggleoptions = {"wingbuffet", "shadowflame", "curse", "adds", "bosskill"}

L:RegisterTranslations("enUS", function() return {
	cmd = "Ebonroc",

	wingbuffet_cmd = "wingbuffet",
	wingbuffet_name = "Wing Buffet Alert",
	wingbuffet_desc = "Warn for Wing Buffet",

	shadowflame_cmd = "shadowflame",
	shadowflame_name = "Shadow Flame Alert",
	shadowflame_desc = "Warn for Shadow Flame",

	curse_cmd = "curse",
	curse_name = "Shadow of Ebonroc Alert",
	curse_desc = "Warn for Shadow of Ebonroc",

	adds_cmd = "adds",
	adds_name = "Shadowflame Spark Alert",
	adds_desc = "Warn for Shadowflame Spark fixate",
	
	
	trigger_wingBuffet = "Ebonroc begins to cast Wing Buffet.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	bar_wingBuffetCast = "Casting Wing Buffet!",
	bar_wingBuffetCd = "Wing Buffet CD",
	msg_wingBuffetCast = "Casting Wing Buffet!",
	msg_wingBuffetSoon = "Wing Buffet in 2 seconds - Taunt now!",
	
	trigger_shadowFlame = "Ebonroc begins to cast Shadow Flame.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	bar_shadowFlameCast = "Casting Shadow Flame!",
	bar_shadowFlameCd = "Shadow Flame CD",
	msg_shadowFlameCast = "Casting Shadow Flame!",
	
	trigger_shadowOfEbonrocYou = "You are afflicted by Shadow of Ebonroc.", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_shadowOfEbonrocOther = "(.+) is afflicted by Shadow of Ebonroc.", --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
	trigger_shadowOfEbonrocFade = "Shadow of Ebonroc fades from (.+).", --CHAT_MSG_SPELL_AURA_GONE_SELF // CHAT_MSG_SPELL_AURA_GONE_PARTY // CHAT_MSG_SPELL_AURA_GONE_OTHER
	msg_shadowOfEbonroc = " has Shadow of Ebonroc - Taunt!",
	bar_shadowOfEbonrocDur = " Shadow of Ebonroc",
	bar_shadowOfEbonrocCd = "Shadow of Ebonroc CD",

	trigger_sparkYou = "Shadowflame Spark's Shadow Shock hits you", --CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE
	trigger_sparkMeleeYou = "Shadowflame Spark hits you", --CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE
	trigger_sparkOther = "Shadowflame Spark's Shadow Shock hits (.+)", --CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE
	msg_sparkYou = "Shadowflame Spark on YOU — Run!",
	msg_sparkOther = "Shadowflame Spark on ",
} end)

local timer = {
	wingBuffetFirstCd = 30,
	wingBuffetCd = 29, --30sec - 1sec cast
	wingBuffetCast = 1,
	
	shadowFlameFirstCd = 16,
	shadowFlameCd = 14, --16 - 2sec cast
	shadowFlameCast = 2,
	
	shadowOfEbonrocCd = 8,
	shadowOfEbonrocDur = 8,
}
local icon = {
	wingBuffet = "INV_Misc_MonsterScales_14",
	shadowFlame = "Spell_Fire_Incinerate",
	shadowOfEbonroc = "Spell_Shadow_GatherShadows",
	spark = "spell_shadow_shadowbolt",
}
local color = {
	wingBuffetCd = "Cyan",
	wingBuffetCast = "Blue",
	
	shadowFlameCd = "Orange",
	shadowFlameCast = "Red",
	
	shadowOfEbonrocCd = "Black",
	shadowOfEbonrocDur = "Magenta",
}
local syncName = {
	wingBuffet = "EbonrocWingBuffet"..module.revision,
	shadowFlame = "EbonrocShadowflame"..module.revision,
	shadowOfEbonroc = "EbonrocShadow"..module.revision,
	shadowOfEbonrocFade = "EbonrocShadowFade"..module.revision,
	spark = "EbonrocSpark"..module.revision,
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

function module:OnEnable()
	--self:RegisterEvent("CHAT_MSG_SAY", "Event") --Debug
	
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event") --trigger_sparkYou, trigger_sparkMeleeYou
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "Event") --trigger_sparkOther
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event") --trigger_wingBuffet, trigger_shadowFlame

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") --trigger_shadowOfEbonrocYou
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") --trigger_shadowOfEbonrocOther
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") --trigger_shadowOfEbonrocOther
	
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event") --trigger_shadowOfEbonrocFade
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event") --trigger_shadowOfEbonrocFade
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event") --trigger_shadowOfEbonrocFade
	
	
	self:ThrottleSync(3, syncName.wingBuffet)
	self:ThrottleSync(3, syncName.shadowFlame)
	self:ThrottleSync(3, syncName.shadowOfEbonroc)
	self:ThrottleSync(3, syncName.shadowOfEbonrocFade)
	self:ThrottleSync(3, syncName.spark)

	-- SuperWoW: get Spark targets directly from cast events
	if SUPERWOW_VERSION then
		self:RegisterCastEventsForUnitName("Shadowflame Spark", "SparkCastEvent")
	end
end

function module:OnSetup()
	self.started = nil
end

function module:OnDisengage()
	self:CancelScheduledEvent("Ebonroc_SparkTargetScan")
end

function module:OnEngage()
	lastSparkAlert = {}

	if self.db.profile.wingbuffet then
		self:Bar(L["bar_wingBuffetCd"], timer.wingBuffetFirstCd, icon.wingBuffet, true, color.wingBuffetCd)
		self:DelayedMessage(timer.wingBuffetFirstCd - 2, L["msg_wingBuffetSoon"], "Attention", false, nil, false)
	end

	if self.db.profile.shadowflame then
		self:Bar(L["bar_shadowFlameCd"], timer.shadowFlameFirstCd, icon.shadowFlame, true, color.shadowFlameCd)
	end

	if self.db.profile.curse then
		self:Bar(L["bar_shadowOfEbonrocCd"], timer.shadowOfEbonrocCd, icon.shadowOfEbonroc, true, color.shadowOfEbonrocCd)
	end

	if self.db.profile.adds and not SUPERWOW_VERSION then
		-- Fallback target scan when SuperWoW is not available
		self:ScheduleRepeatingEvent("Ebonroc_SparkTargetScan", self.SparkTargetScan, 0.5, self)
	end
end

local lastSparkAlert = {}

-- SuperWoW: UNIT_CASTEVENT callback for Shadowflame Spark casts
function module:SparkCastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
	if eventType == "START" or eventType == "CAST" then
		local targetName = UnitName(targetGuid)
		if targetName and self.db.profile.adds then
			local now = GetTime()
			if not lastSparkAlert[targetName] or (now - lastSparkAlert[targetName]) > 3 then
				lastSparkAlert[targetName] = now
				self:Sync(syncName.spark .. " " .. targetName)
			end
		end
	end
end

-- Non-SuperWoW fallback: scan raid members' targets for Sparks
function module:SparkTargetScan()
	for i = 1, GetNumRaidMembers() do
		local raidTarget = "Raid"..i.."Target"
		if UnitName(raidTarget) == "Shadowflame Spark" and UnitExists(raidTarget.."Target") then
			local fixateTarget = UnitName(raidTarget.."Target")
			if fixateTarget then
				local now = GetTime()
				if not lastSparkAlert[fixateTarget] or (now - lastSparkAlert[fixateTarget]) > 3 then
					lastSparkAlert[fixateTarget] = now
					self:Sync(syncName.spark .. " " .. fixateTarget)
				end
			end
		end
	end
end

function module:Event(msg)
	-- Damage fallback: fires if SuperWoW and target scan both missed this Spark
	if string.find(msg, L["trigger_sparkYou"]) or string.find(msg, L["trigger_sparkMeleeYou"]) then
		if self.db.profile.adds then
			local me = UnitName("Player")
			local now = GetTime()
			if not lastSparkAlert[me] or (now - lastSparkAlert[me]) > 3 then
				lastSparkAlert[me] = now
				self:Sync(syncName.spark .. " " .. me)
			end
		end
		return

	elseif string.find(msg, L["trigger_sparkOther"]) then
		if self.db.profile.adds then
			local _,_,sparkTarget,_ = string.find(msg, L["trigger_sparkOther"])
			local now = GetTime()
			if not lastSparkAlert[sparkTarget] or (now - lastSparkAlert[sparkTarget]) > 3 then
				lastSparkAlert[sparkTarget] = now
				self:Sync(syncName.spark .. " " .. sparkTarget)
			end
		end
		return

	elseif msg == L["trigger_wingBuffet"] then
		self:Sync(syncName.wingBuffet)
	
	elseif msg == L["trigger_shadowFlame"] then
		self:Sync(syncName.shadowFlame)
	
	elseif msg == L["trigger_shadowOfEbonrocYou"] then
		self:Sync(syncName.shadowOfEbonroc .. " " .. UnitName("Player"))
	
	elseif string.find(msg, L["trigger_shadowOfEbonrocOther"]) then
		local _,_,shadowOfEbonrocPlayer,_ = string.find(msg, L["trigger_shadowOfEbonrocOther"])
		self:Sync(syncName.shadowOfEbonroc .. " " .. shadowOfEbonrocPlayer)
		
	elseif string.find(msg, L["trigger_shadowOfEbonrocFade"]) then
		local _,_,shadowOfEbonrocFadePlayer,_ = string.find(msg, L["trigger_shadowOfEbonrocFade"])
		if shadowOfEbonrocFadePlayer == "you" then shadowOfEbonrocFadePlayer = UnitName("Player") end
		self:Sync(syncName.shadowOfEbonrocFade .. " " .. shadowOfEbonrocFadePlayer)
	end
end


function module:BigWigs_RecvSync(sync, rest, nick)
	sync = translateSync(sync)

	if sync == syncName.wingBuffet and self.db.profile.wingbuffet then
		self:WingBuffet()
	elseif sync == syncName.shadowFlame and self.db.profile.shadowflame then
		self:ShadowFlame()
	elseif sync == syncName.shadowOfEbonroc and rest and self.db.profile.curse then
		rest = self:ValidatePlayerSync(rest, sync, nick)
		if rest then self:ShadowOfEbonroc(rest) end
	elseif sync == syncName.shadowOfEbonrocFade and rest and self.db.profile.curse then
		rest = self:ValidatePlayerSync(rest, sync, nick)
		if rest then self:ShadowOfEbonrocFade(rest) end

	elseif sync == syncName.spark and rest and self.db.profile.adds then
		rest = self:ValidatePlayerSync(rest, sync, nick)
		if rest then self:SparkTarget(rest) end
	end
end


function module:WingBuffet()
	self:CancelDelayedMessage(L["msg_wingBuffetSoon"])
	self:RemoveBar(L["bar_wingBuffetCd"])
	
	self:Bar(L["bar_wingBuffetCast"], timer.wingBuffetCast, icon.wingBuffet, true, color.wingBuffetCast)
	
	self:DelayedBar(timer.wingBuffetCast, L["bar_wingBuffetCd"], timer.wingBuffetCd, icon.wingBuffet, true, color.wingBuffetCd)
	self:DelayedMessage(timer.wingBuffetCast + timer.wingBuffetCd - 2, L["msg_wingBuffetSoon"], "Attention", false, nil, false)
end

function module:ShadowFlame()
	self:RemoveBar(L["bar_shadowFlameCd"])
	
	self:Bar(L["bar_shadowFlameCast"], timer.shadowFlameCast, icon.shadowFlame, true, color.shadowFlameCast)
	self:Message(L["msg_shadowFlameCast"], "Urgent", false, nil, false)
	
	self:DelayedBar(timer.shadowFlameCast, L["bar_shadowFlameCd"], timer.shadowFlameCd, icon.shadowFlame, true, color.shadowFlameCd)
end

function module:ShadowOfEbonroc(rest)
	self:RemoveBar(L["bar_shadowOfEbonrocCd"])
	
	self:Bar(rest..L["bar_shadowOfEbonrocDur"], timer.shadowOfEbonrocDur, icon.shadowOfEbonroc, true, color.shadowOfEbonrocDur)
	self:Message(rest..L["msg_shadowOfEbonroc"], "Important", false, nil, false)
	
	if rest == UnitName("Player") then
		self:WarningSign(icon.shadowOfEbonroc, timer.shadowOfEbonrocDur)
	end
end

function module:ShadowOfEbonrocFade(rest)
	self:RemoveBar(rest..L["bar_shadowOfEbonrocDur"])

	if rest == UnitName("Player") then
		self:RemoveWarningSign(icon.shadowOfEbonroc)
	end
end

function module:SparkTarget(rest)
	-- Deduplicate: scan and damage fallback can both fire for the same target
	local now = GetTime()
	if lastSparkAlert[rest] and (now - lastSparkAlert[rest]) < 3 then return end
	lastSparkAlert[rest] = now

	if rest == UnitName("Player") then
		self:Message(L["msg_sparkYou"], "Personal", false, nil, false)
		self:Sound("RunAway")
		self:WarningSign(icon.spark, 2)
	else
		self:Message(L["msg_sparkOther"]..rest.."!", "Attention", false, nil, false)
	end
end
