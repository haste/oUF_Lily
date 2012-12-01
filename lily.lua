--[[-------------------------------------------------------------------------
  Trond A Ekseth grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]
local name, addon = ...

local _, CLASS = UnitClass'player'
local TEXTURE = [[Interface\AddOns\oUF_Lily\textures\statusbar]]

local HealthThresholds = {
	WARLOCK = .2,
	ROGUE = .35,
}

local updateName = function(self, event, unit)
	if(self.unit == unit) then
		local r, g, b, t
		if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
			r, g, b = .6, .6, .6
		elseif(UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			t = self.colors.class[class]
		else
			t = self.colors.reaction[UnitReaction(unit, "player")]
		end

		if(t) then
			r, g, b = t[1], t[2], t[3]
		end

		if(r) then
			self.Name:SetTextColor(r, g, b)
		end
	end
end

local PostUpdateHealth = function(Health, unit, min, max)
	if(UnitIsDead(unit)) then
		Health:SetValue(0)
	elseif(UnitIsGhost(unit)) then
		Health:SetValue(0)
	end

	local threshold = HealthThresholds[CLASS]
	if(threshold) then
		local Border = Health.__owner.Border
		if(max > 0 and min > 0 and min/max <= threshold) then
			Border:SetColor(.8, .1, .1, .9)
		else
			Border:SetColor(0, 0, 0, .9)
		end
	end

	return updateName(Health:GetParent(), 'PostUpdateHealth', unit)
end

local PostCastStart = function(Castbar, unit, spell, spellrank)
	Castbar:GetParent().Name:SetText('×' .. spell)
end

local PostCastStop = function(Castbar, unit)
	local name
	if(unit:sub(1,4) == 'boss') then
		-- And people complain about Lua's lack for full regexp support.
		name = UnitName(unit):gsub('(%u)%S* %l*%s*', '%1 ')
	else
		name = UnitName(unit)
	end

	Castbar:GetParent().Name:SetText(name)
end

local PostCastStopUpdate = function(self, event, unit)
	if(unit ~= self.unit) then return end
	return PostCastStop(self.Castbar, unit)
end

local overlayProxy = function(overlay, ...)
	overlay:GetParent().Border:SetColor(...)
end

local overlayHide = function(overlay)
	overlay:GetParent().Border:SetColor(0, 0, 0, .9)
end

local PostCreateIcon = function(Auras, button)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint"BOTTOM"

	button.icon:SetTexCoord(.07, .93, .07, .93)

	-- XXX: Actually make a glow texture of auras.
	addon.CreateBorder(button, [[Interface\AddOns\oUF_Lily\textures\glow]])
	button.Border:SetColor(0, 0, 0, .9)
	local overlay = button.overlay
	overlay.SetVertexColor = overlayProxy
	overlay:Hide()
	overlay.Show = overlay.Hide
	overlay.Hide = overlayHide
end

local PostUpdateIcon
do
	local playerUnits = {
		player = true,
		pet = true,
		vehicle = true,
	}

	PostUpdateIcon = function(icons, unit, icon, index, offset, filter, isDebuff)
		local texture = icon.icon
		if(playerUnits[icon.owner]) then
			texture:SetDesaturated(false)
		else
			texture:SetDesaturated(true)
		end
	end
end

local PostUpdateGapIcon = function(Auras, unit, icon, visibleBuffs)
	if(Auras.currentGap) then
		Auras.currentGap.Border:Show()
	end

	icon.Border:Hide()
	Auras.currentGap = icon
end

local PostUpdatePower = function(Power, unit, min, max)
	local Health = Power:GetParent().Health
	if(
		min == 0 or max == 0 or not UnitIsConnected(unit) or
		UnitIsDead(unit) or UnitIsGhost(unit)
	) then
		Power:Hide()
		Health:SetHeight(23)
	else
		Power:Show()
		Health:SetHeight(20)
	end
end

local RAID_TARGET_UPDATE = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."23|t")
	else
		self.RIcon:SetText()
	end
end

local CreateAura = function(self, num)
	local size = 23
	local Auras = CreateFrame("Frame", nil, self)

	Auras:SetSize(num * (size + 4), size)
	Auras.num = num
	Auras.size = size
	Auras.spacing = 4

	Auras.PostCreateIcon = PostCreateIcon

	return Auras
end

local Shared = function(self, unit, isSingle)
	self.menu = addon.menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"AnyUp"

	addon.CreateBorder(self, [[Interface\AddOns\oUF_Lily\textures\glow]])
	self.Border:SetColor(0, 0, 0, .9)

	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetHeight(20)
	Health:SetStatusBarTexture(TEXTURE)
	Health:SetStatusBarColor(.25, .25, .25)

	Health.frequentUpdates = true

	Health:SetPoint"TOP"
	Health:SetPoint"LEFT"
	Health:SetPoint"RIGHT"

	self.Health = Health

	local Background = Health:CreateTexture(nil, 'BORDER')
	Background:SetTexture(0, 0, 0, .4)
	Background:SetAllPoints()

	local HealthPoints = Health:CreateFontString(nil, "OVERLAY")
	HealthPoints:SetPoint("RIGHT", -2, 0)
	HealthPoints:SetFontObject(GameFontNormalSmall)
	HealthPoints:SetTextColor(1, 1, 1)
	self:Tag(HealthPoints, '[|cffc41f3b>dead<|r][|cff999999>offline<|r][lily:health]')

	Health.value = HealthPoints

	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetHeight(3)
	Power:SetStatusBarTexture(TEXTURE)

	Power.frequentUpdates = true
	Power.colorTapping = true
	Power.colorClass = true
	Power.colorReaction = true

	Power:SetPoint"LEFT"
	Power:SetPoint"RIGHT"
	Power:SetPoint("TOP", Health, "BOTTOM")

	self.Power = Power

	local Background = Power:CreateTexture(nil, 'BORDER')
	Background:SetTexture(0, 0, 0, .4)
	Background:SetAllPoints()

	local PowerPoints = Power:CreateFontString(nil, "OVERLAY")
	PowerPoints:SetPoint("RIGHT", HealthPoints, "LEFT", 0, 0)
	PowerPoints:SetFontObject(GameFontNormalSmall)
	PowerPoints:SetTextColor(1, 1, 1)
	self:Tag(PowerPoints, '[lily:power< | ]')

	Power.value = PowerPoints

	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetStatusBarTexture(TEXTURE)
	Castbar:SetStatusBarColor(1, .25, .35, .5)
	Castbar:SetAllPoints(Health)
	Castbar:SetToplevel(true)

	self.Castbar = Castbar

	local Leader = self:CreateTexture(nil, "OVERLAY")
	Leader:SetHeight(16)
	Leader:SetWidth(16)
	Leader:SetPoint("BOTTOM", Health, "TOP", 0, -5)

	self.Leader = Leader

	local MasterLooter = self:CreateTexture(nil, 'OVERLAY')
	MasterLooter:SetHeight(16)
	MasterLooter:SetWidth(16)
	MasterLooter:SetPoint('LEFT', Leader, 'RIGHT')

	self.MasterLooter = MasterLooter

	local RaidIcon = Health:CreateFontString(nil, "OVERLAY")
	RaidIcon:SetPoint("LEFT", 2, 4)
	RaidIcon:SetJustifyH"LEFT"
	RaidIcon:SetFontObject(GameFontNormalSmall)
	RaidIcon:SetTextColor(1, 1, 1)

	self.RIcon = RaidIcon
	self:RegisterEvent("RAID_TARGET_UPDATE", RAID_TARGET_UPDATE)
	table.insert(self.__elements, RAID_TARGET_UPDATE)

	local name = Health:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", RaidIcon, "RIGHT", 0, -4)
	name:SetPoint("RIGHT", PowerPoints, "LEFT")
	name:SetJustifyH"LEFT"
	name:SetFontObject(GameFontNormalSmall)
	name:SetTextColor(1, 1, 1)

	self.Name = name

	if(isSingle) then
		self:SetSize(220, 23)
	end

	self:RegisterEvent('UNIT_NAME_UPDATE', PostCastStopUpdate)
	table.insert(self.__elements, PostCastStopUpdate)

	Castbar.PostChannelStart = PostCastStart
	Castbar.PostCastStart = PostCastStart

	Castbar.PostCastStop = PostCastStop
	Castbar.PostChannelStop = PostCastStop

	Health.PostUpdate = PostUpdateHealth
	Power.PostUpdate = PostUpdatePower
end

local UnitSpecific = {
	player = function(self, ...)
		Shared(self, ...)

		local PowerPoints = self.Power.value
		if(CLASS == 'WARLOCK') then
			self:Tag(PowerPoints, '[soulshards< | ][lily:power< | ]')
		elseif(CLASS == 'ROGUE') then
			self:Tag(PowerPoints, '[cpoints< | ][lily:power< | ]')
		end

		local Debuffs = CreateAura(self, 4)
		Debuffs:SetPoint("LEFT", self, "RIGHT", 4, 0)
		Debuffs.showDebuffType = true
		Debuffs.PostUpdateIcon = PostUpdateIcon

		self.Debuffs = Debuffs

		local AltPowerBar = CreateFrame("StatusBar", nil, self)
		AltPowerBar:SetHeight(3)
		AltPowerBar:SetStatusBarTexture(TEXTURE)
		AltPowerBar:SetStatusBarColor(1, 1, 1)

		AltPowerBar:SetPoint"LEFT"
		AltPowerBar:SetPoint"RIGHT"
		AltPowerBar:SetPoint("TOP", self.Power, "BOTTOM")

		self.AltPowerBar = AltPowerBar

		local Background = AltPowerBar:CreateTexture(nil, 'BORDER')
		Background:SetTexture(0, 0, 0, .4)
		Background:SetAllPoints()

		local CPoints = {}
		for index = 1, 5 do
			local Icon = self:CreateTexture(nil, 'BACKGROUND')

			Icon:SetTexCoord(0.45703125, 0.60546875, 0.44531250, 0.73437500)
			Icon:SetTexture([[Interface\PlayerFrame\Priest-ShadowUI]])
			Icon:SetDesaturated(true)
			Icon:SetVertexColor(1, .96, .41)

			Icon:SetSize(16, 16)
			Icon:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * Icon:GetWidth(), 0)

			CPoints[index] = Icon
		end

		self.CPoints = CPoints

		local ClassIcons = {}
		for index = 1, 5 do
			local Icon = self:CreateTexture(nil, 'BACKGROUND')

			Icon:SetSize(16, 16)
			Icon:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * Icon:GetWidth(), 0)

			ClassIcons[index] = Icon
		end

		self.ClassIcons = ClassIcons
	end,

	target = function(self, ...)
		Shared(self, ...)

		local Buffs = CreateAura(self, 8)
		Buffs:SetPoint("RIGHT", self, "LEFT", -4, 0)
		Buffs:SetPoint('TOP')
		Buffs:SetPoint('BOTTOM')

		Buffs.initialAnchor = "BOTTOMRIGHT"
		Buffs["growth-x"] = "LEFT"

		Buffs.PostUpdateIcon = PostUpdateIcon

		self.Buffs = Buffs

		local Debuffs = CreateAura(self, 8)
		Debuffs:SetPoint("LEFT", self, "RIGHT", 4, 0)
		Debuffs.showDebuffType = true
		Debuffs.PostUpdateIcon = PostUpdateIcon

		self.Debuffs = Debuffs
	end,

	boss = function(self, ...)
		Shared(self, ...)

		self:Tag(self.Health.value, '[perhp] | [lily:health]')

		-- Disable the power value, it isn't really importent.
		self:Untag(self.Power.value)
		self.Power.value:Hide()

		self:SetWidth(140)
	end,
}
UnitSpecific.focus = UnitSpecific.target

do
	local range = {
		insideAlpha = 1,
		outsideAlpha = .5,
	}

	UnitSpecific.party = function(self, ...)
		Shared(self, ...)

		local Health, Power = self.Health, self.Power

		local LFDRole = self:CreateTexture(nil, "OVERLAY")
		LFDRole:SetSize(16, 16)
		LFDRole:SetPoint("RIGHT", self, "LEFT", -3, 0)

		self.LFDRole = LFDRole

		local Buffs = CreateAura(self, 2)
		Buffs:SetPoint("LEFT", self, "RIGHT", 4, 0)
		Buffs.CustomFilter = addon.PartyBuffsCustomFilter
		Buffs.PostUpdate = addon.PartyBuffsPostUpdate

		self.Buffs = Buffs

		local Auras = CreateAura(self,  9)
		Auras:SetPoint("LEFT", Buffs, "RIGHT", 4, 0)

		Auras.showDebuffType = true
		Auras.gap = true
		Auras.numBuffs = 4
		Auras.numDebuffs = 4

		Auras.PostUpdateGapIcon = PostUpdateGapIcon
		Auras.CustomFilter = addon.PartyAurasCustomFilter

		self.Auras = Auras

		self.Range = range
	end
end

oUF:RegisterStyle("Lily", Shared)
for unit,layout in next, UnitSpecific do
	-- Capitalize the unit name, so it looks better.
	oUF:RegisterStyle('Lily - ' .. unit:gsub("^%l", string.upper), layout)
end

-- A small helper to change the style into a unit specific, if it exists.
local spawnHelper = function(self, unit, ...)
	if(UnitSpecific[unit]) then
		self:SetActiveStyle('Lily - ' .. unit:gsub("^%l", string.upper))
	elseif(UnitSpecific[unit:match('%D+')]) then -- boss1 -> boss
		self:SetActiveStyle('Lily - ' .. unit:match('%D+'):gsub("^%l", string.upper))
	else
		self:SetActiveStyle'Lily'
	end

	local object = self:Spawn(unit)
	object:SetPoint(...)
	return object
end

oUF:Factory(function(self)
	local base = 100
	spawnHelper(self, 'focus', "BOTTOM", 0, base + (40 * 1))
	spawnHelper(self, 'pet', 'BOTTOM', 0, base + (40 * 2))
	spawnHelper(self, 'player', 'BOTTOM', 0, base + (40 * 3))
	spawnHelper(self, 'target', 'BOTTOM', 0, base + (40 * 4))
	spawnHelper(self, 'targettarget', 'BOTTOM', 0, base + (40 * 5))

	for n=1, MAX_BOSS_FRAMES or 5 do
		spawnHelper(self,'boss' .. n, 'TOPRIGHT', -10, -155 - (40 * n))
	end

	self:SetActiveStyle'Lily - Party'
	local party = self:SpawnHeader(
		nil, nil, 'raid,party,solo',
		'showParty', true, 'showPlayer', true, 'showSolo', true, 'yOffset', -20,
		'oUF-initialConfigFunction', [[
			self:SetHeight(23)
			self:SetWidth(220)
		]]
	)
	party:SetPoint("TOPLEFT", 30, -30)
end)
