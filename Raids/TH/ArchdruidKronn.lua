
local module, L = BigWigs:ModuleDeclaration("Archdruid Kronn", "Timbermaw Hold")

module.revision = 30138
module.enabletrigger = module.translatedName
module.toggleoptions = {"nightmareburst", "lucidnightmare", "thornburst", "dreamfever", "intruder", -1, "hpframe", "addcounter", "intruderstacks", "bosskill"}
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

	hpframe_cmd = "hpframe",
	hpframe_name = "Boss Health Frame",
	hpframe_desc = "Show health of Archdruid Kronn and Dreamform of Kronn",

	addcounter_cmd = "addcounter",
	addcounter_name = "Add Counter",
	addcounter_desc = "Show counter for adds on each side",

	intruderstacks_cmd = "intruderstacks",
	intruderstacks_name = "Intruder Stacks Alert (5)",
	intruderstacks_desc = "Alert when you reach 5 stacks of Intruder of the Dream",

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

	trigger_intruderStacksSelf = "You are afflicted by Intruder of the Dream %((%d+)%)",
	trigger_intruderStacksOther = "(.+) is afflicted by Intruder of the Dream %((%d+)%)",
	msg_intruderStacks = "Intruder of the Dream - %d STACKS on YOU!",

	font = "Fonts\\FRIZQT__.TTF",
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

-- Mob names for tracking
local bossName = "Archdruid Kronn"
local dreamformName = "Dreamform of Kronn"
local xavianFormName = "Xavian Form"
local xavianImageName = "Xavian Image"
local invadingMiasmaName = "Invading Miasma"
local dreadfulMiasmaName = "Dreadful Miasma"

local font = "Fonts\\FRIZQT__.TTF"
local fontSize = 11

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "AddDeathEvent")

	self:ThrottleSync(5, syncName.nightmareBurst)
	self:ThrottleSync(1, syncName.lucidNightmare)
	self:ThrottleSync(5, syncName.thornBurst)
	self:ThrottleSync(1, syncName.dreamFever)
	self:ThrottleSync(10, syncName.intruder)
end

function module:OnSetup()
	self.started = nil
	self.kronnHp = 100
	self.dreamformHp = 100
	self.xavianFormCount = 0
	self.xavianImageCount = 0
	self.invadingMiasmaCount = 0
	self.dreadfulMiasmaCount = 0
end

function module:OnEngage()
	self.kronnHp = 100
	self.dreamformHp = 100
	self.xavianFormCount = 0
	self.xavianImageCount = 0
	self.invadingMiasmaCount = 0
	self.dreadfulMiasmaCount = 0

	if self.db.profile.hpframe or self.db.profile.addcounter then
		self:ScheduleRepeatingEvent("KronnCheckStatus", self.CheckStatus, 1, self)
	end
end

function module:OnDisengage()
	self:CancelScheduledEvent("KronnCheckStatus")
	if self.statusFrame then
		self.statusFrame:Hide()
	end
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
		-- Check for stacks on self
		local _, _, stacks = string.find(msg, "You are afflicted by Intruder of the Dream %((%d+)%)")
		if stacks then
			stacks = tonumber(stacks)
			if stacks >= 5 and self.db.profile.intruderstacks then
				self:Message(string.format(L["msg_intruderStacks"], stacks), "Urgent", false, nil, false)
				self:Sound("RunAway")
				self:WarningSign(icon.intruder, 2, nil, stacks .. " Stacks!")
			end
		end
		self:Sync(syncName.intruder)
	end
end

function module:AddDeathEvent(msg)
	if string.find(msg, "Xavian Form dies") then
		self.xavianFormCount = math.max(0, self.xavianFormCount - 1)
		self:UpdateStatusFrame()
	elseif string.find(msg, "Xavian Image dies") then
		self.xavianImageCount = math.max(0, self.xavianImageCount - 1)
		self:UpdateStatusFrame()
	elseif string.find(msg, "Invading Miasma dies") then
		self.invadingMiasmaCount = math.max(0, self.invadingMiasmaCount - 1)
		self:UpdateStatusFrame()
	elseif string.find(msg, "Dreadful Miasma dies") then
		self.dreadfulMiasmaCount = math.max(0, self.dreadfulMiasmaCount - 1)
		self:UpdateStatusFrame()
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

------------------------------
--    Status Tracking       --
------------------------------

function module:CheckStatus()
	local kronnHp = nil
	local dreamformHp = nil
	local xavianFormCount = 0
	local xavianImageCount = 0
	local invadingMiasmaCount = 0
	local dreadfulMiasmaCount = 0

	-- Track which units we've already counted to avoid duplicates
	local countedUnits = {}

	for i = 1, GetNumRaidMembers() do
		local targetString = "Raid" .. i .. "Target"
		local targetName = UnitName(targetString)

		if targetName == bossName and not kronnHp then
			local maxHp = UnitHealthMax(targetString)
			if maxHp and maxHp > 0 then
				kronnHp = math.ceil((UnitHealth(targetString) / maxHp) * 100)
			end
		elseif targetName == dreamformName and not dreamformHp then
			local maxHp = UnitHealthMax(targetString)
			if maxHp and maxHp > 0 then
				dreamformHp = math.ceil((UnitHealth(targetString) / maxHp) * 100)
			end
		elseif targetName == xavianFormName then
			local dominated = false
			for _, u in countedUnits do
				if UnitIsUnit(targetString, u) then
					dominated = true
					break
				end
			end
			if not dominated then
				xavianFormCount = xavianFormCount + 1
				table.insert(countedUnits, targetString)
			end
		elseif targetName == xavianImageName then
			local dominated = false
			for _, u in countedUnits do
				if UnitIsUnit(targetString, u) then
					dominated = true
					break
				end
			end
			if not dominated then
				xavianImageCount = xavianImageCount + 1
				table.insert(countedUnits, targetString)
			end
		elseif targetName == invadingMiasmaName then
			local dominated = false
			for _, u in countedUnits do
				if UnitIsUnit(targetString, u) then
					dominated = true
					break
				end
			end
			if not dominated then
				invadingMiasmaCount = invadingMiasmaCount + 1
				table.insert(countedUnits, targetString)
			end
		elseif targetName == dreadfulMiasmaName then
			local dominated = false
			for _, u in countedUnits do
				if UnitIsUnit(targetString, u) then
					dominated = true
					break
				end
			end
			if not dominated then
				dreadfulMiasmaCount = dreadfulMiasmaCount + 1
				table.insert(countedUnits, targetString)
			end
		end
	end

	-- Also check player target
	local targetName = UnitName("target")
	if targetName == bossName and not kronnHp then
		local maxHp = UnitHealthMax("target")
		if maxHp and maxHp > 0 then
			kronnHp = math.ceil((UnitHealth("target") / maxHp) * 100)
		end
	elseif targetName == dreamformName and not dreamformHp then
		local maxHp = UnitHealthMax("target")
		if maxHp and maxHp > 0 then
			dreamformHp = math.ceil((UnitHealth("target") / maxHp) * 100)
		end
	end

	if kronnHp then self.kronnHp = kronnHp end
	if dreamformHp then self.dreamformHp = dreamformHp end

	-- Update add counts - use scanned counts if we found any, otherwise keep previous
	if xavianFormCount > 0 or self.xavianFormCount == 0 then
		self.xavianFormCount = xavianFormCount
	end
	if xavianImageCount > 0 or self.xavianImageCount == 0 then
		self.xavianImageCount = xavianImageCount
	end
	if invadingMiasmaCount > 0 or self.invadingMiasmaCount == 0 then
		self.invadingMiasmaCount = invadingMiasmaCount
	end
	if dreadfulMiasmaCount > 0 or self.dreadfulMiasmaCount == 0 then
		self.dreadfulMiasmaCount = dreadfulMiasmaCount
	end

	self:UpdateStatusFrame()
end

------------------------------
--    Status Frame          --
------------------------------

function module:UpdateStatusFrame()
	if not self.db.profile.hpframe and not self.db.profile.addcounter then
		return
	end

	if not self.statusFrame then
		self:SetupStatusFrame()
	end

	self.statusFrame:Show()

	-- Update health displays
	if self.db.profile.hpframe then
		local kronnColor = self:GetHealthColor(self.kronnHp, true)
		local dreamformColor = self:GetHealthColor(self.dreamformHp, false)

		self.statusFrame.kronnHpText:SetText(string.format("%d%%", self.kronnHp))
		self.statusFrame.kronnHpText:SetTextColor(kronnColor.r, kronnColor.g, kronnColor.b)

		self.statusFrame.dreamformHpText:SetText(string.format("%d%%", self.dreamformHp))
		self.statusFrame.dreamformHpText:SetTextColor(dreamformColor.r, dreamformColor.g, dreamformColor.b)

		self.statusFrame.kronnLabel:Show()
		self.statusFrame.kronnHpText:Show()
		self.statusFrame.dreamformLabel:Show()
		self.statusFrame.dreamformHpText:Show()
	else
		self.statusFrame.kronnLabel:Hide()
		self.statusFrame.kronnHpText:Hide()
		self.statusFrame.dreamformLabel:Hide()
		self.statusFrame.dreamformHpText:Hide()
	end

	-- Update add counter displays
	if self.db.profile.addcounter then
		local dmgAdds = ""
		if self.xavianFormCount > 0 then
			dmgAdds = self.xavianFormCount .. " Form"
		end
		if self.invadingMiasmaCount > 0 then
			if dmgAdds ~= "" then dmgAdds = dmgAdds .. ", " end
			dmgAdds = dmgAdds .. self.invadingMiasmaCount .. " Miasma"
		end
		if dmgAdds == "" then dmgAdds = "0" end

		local healAdds = ""
		if self.xavianImageCount > 0 then
			healAdds = self.xavianImageCount .. " Image"
		end
		if self.dreadfulMiasmaCount > 0 then
			if healAdds ~= "" then healAdds = healAdds .. ", " end
			healAdds = healAdds .. self.dreadfulMiasmaCount .. " Miasma"
		end
		if healAdds == "" then healAdds = "0" end

		self.statusFrame.dmgAddsText:SetText(dmgAdds)
		self.statusFrame.healAddsText:SetText(healAdds)

		self.statusFrame.dmgAddsLabel:Show()
		self.statusFrame.dmgAddsText:Show()
		self.statusFrame.healAddsLabel:Show()
		self.statusFrame.healAddsText:Show()
	else
		self.statusFrame.dmgAddsLabel:Hide()
		self.statusFrame.dmgAddsText:Hide()
		self.statusFrame.healAddsLabel:Hide()
		self.statusFrame.healAddsText:Hide()
	end
end

-- For damage side boss: lower is better (green at low, red at high)
-- For healing side boss: higher is better (green at high, red at low)
function module:GetHealthColor(hp, isDamageSide)
	if isDamageSide then
		-- DPS boss: low hp = good (green), high hp = bad (red)
		if hp <= 30 then
			return {r = 0, g = 1, b = 0}
		elseif hp <= 60 then
			return {r = 1, g = 1, b = 0}
		else
			return {r = 1, g = 0.5, b = 0}
		end
	else
		-- Heal boss: high hp = good (green), low hp = bad (red)
		if hp >= 70 then
			return {r = 0, g = 1, b = 0}
		elseif hp >= 40 then
			return {r = 1, g = 1, b = 0}
		else
			return {r = 1, g = 0.2, b = 0.2}
		end
	end
end

function module:SetupStatusFrame()
	if self.statusFrame then return end

	local frame = CreateFrame("Frame", "BigWigsKronnStatusFrame", UIParent)
	frame:Hide()
	frame:SetWidth(200)
	frame:SetHeight(120)
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
		edgeFile = "Interface\\AddOns\\BigWigs\\Textures\\otravi-semi-full-border", edgeSize = 32,
		insets = {left = 1, right = 1, top = 20, bottom = 1},
	})
	frame:SetBackdropColor(0, 0, 0, 0.85)
	frame:SetBackdropBorderColor(0.6, 0.2, 0.8)
	frame:ClearAllPoints()

	local s = frame:GetEffectiveScale()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (self.db.profile.statusframeposx or 300) / s, (self.db.profile.statusframeposy or 600) / s)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetMovable(true)
	frame:SetScript("OnDragStart", function() this:StartMoving() end)
	frame:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
		self:SaveStatusFramePosition()
	end)

	local yOffset = -14

	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetPoint("TOP", frame, "TOP", 0, yOffset)
	title:SetFont(font, fontSize + 1)
	title:SetText("|cffff8800Archdruid Kronn|r")
	title:SetShadowOffset(0.8, -0.8)
	title:SetShadowColor(0, 0, 0, 1)
	yOffset = yOffset - 16

	-- === Damage Side ===
	local dmgHeader = frame:CreateFontString(nil, "OVERLAY")
	dmgHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)
	dmgHeader:SetFont(font, fontSize)
	dmgHeader:SetText("|cffff4444DMG Side:|r")
	dmgHeader:SetShadowOffset(0.8, -0.8)
	dmgHeader:SetShadowColor(0, 0, 0, 1)

	local kronnHpText = frame:CreateFontString(nil, "OVERLAY")
	kronnHpText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, yOffset)
	kronnHpText:SetFont(font, fontSize)
	kronnHpText:SetJustifyH("RIGHT")
	kronnHpText:SetText("100%")
	kronnHpText:SetShadowOffset(0.8, -0.8)
	kronnHpText:SetShadowColor(0, 0, 0, 1)
	frame.kronnLabel = dmgHeader
	frame.kronnHpText = kronnHpText
	yOffset = yOffset - 14

	-- Damage side adds
	local dmgAddsLabel = frame:CreateFontString(nil, "OVERLAY")
	dmgAddsLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, yOffset)
	dmgAddsLabel:SetFont(font, fontSize - 1)
	dmgAddsLabel:SetText("|cffccccccAdds:|r")
	dmgAddsLabel:SetShadowOffset(0.8, -0.8)
	dmgAddsLabel:SetShadowColor(0, 0, 0, 1)

	local dmgAddsText = frame:CreateFontString(nil, "OVERLAY")
	dmgAddsText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, yOffset)
	dmgAddsText:SetFont(font, fontSize - 1)
	dmgAddsText:SetJustifyH("RIGHT")
	dmgAddsText:SetText("0")
	dmgAddsText:SetTextColor(1, 1, 1)
	dmgAddsText:SetShadowOffset(0.8, -0.8)
	dmgAddsText:SetShadowColor(0, 0, 0, 1)
	frame.dmgAddsLabel = dmgAddsLabel
	frame.dmgAddsText = dmgAddsText
	yOffset = yOffset - 16

	-- === Healing Side ===
	local healHeader = frame:CreateFontString(nil, "OVERLAY")
	healHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, yOffset)
	healHeader:SetFont(font, fontSize)
	healHeader:SetText("|cff44ff44HEAL Side:|r")
	healHeader:SetShadowOffset(0.8, -0.8)
	healHeader:SetShadowColor(0, 0, 0, 1)

	local dreamformHpText = frame:CreateFontString(nil, "OVERLAY")
	dreamformHpText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, yOffset)
	dreamformHpText:SetFont(font, fontSize)
	dreamformHpText:SetJustifyH("RIGHT")
	dreamformHpText:SetText("100%")
	dreamformHpText:SetShadowOffset(0.8, -0.8)
	dreamformHpText:SetShadowColor(0, 0, 0, 1)
	frame.dreamformLabel = healHeader
	frame.dreamformHpText = dreamformHpText
	yOffset = yOffset - 14

	-- Healing side adds
	local healAddsLabel = frame:CreateFontString(nil, "OVERLAY")
	healAddsLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, yOffset)
	healAddsLabel:SetFont(font, fontSize - 1)
	healAddsLabel:SetText("|cffccccccAdds:|r")
	healAddsLabel:SetShadowOffset(0.8, -0.8)
	healAddsLabel:SetShadowColor(0, 0, 0, 1)

	local healAddsText = frame:CreateFontString(nil, "OVERLAY")
	healAddsText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, yOffset)
	healAddsText:SetFont(font, fontSize - 1)
	healAddsText:SetJustifyH("RIGHT")
	healAddsText:SetText("0")
	healAddsText:SetTextColor(1, 1, 1)
	healAddsText:SetShadowOffset(0.8, -0.8)
	healAddsText:SetShadowColor(0, 0, 0, 1)
	frame.healAddsLabel = healAddsLabel
	frame.healAddsText = healAddsText

	self.statusFrame = frame
end

function module:SaveStatusFramePosition()
	if not self.statusFrame then return end
	local s = self.statusFrame:GetEffectiveScale()
	self.db.profile.statusframeposx = self.statusFrame:GetLeft() * s
	self.db.profile.statusframeposy = self.statusFrame:GetTop() * s
end
