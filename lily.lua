--[[-------------------------------------------------------------------------
  Trond A Ekseth grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]
local name, addon = ...

local TEXTURE = [[Interface\AddOns\oUF_Lily\textures\statusbar]]

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

	Health:SetStatusBarColor(.25, .25, .35)
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

local PostCreateIcon = function(Auras, button)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint"BOTTOM"

	button.icon:SetTexCoord(.07, .93, .07, .93)
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

local PostUpdatePower = function(Power, unit, min, max)
	local Health = Power:GetParent().Health
	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		Power:SetValue(0)
		Health:SetHeight(22)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		Power:SetValue(0)
		Health:SetHeight(22)
	else
		Health:SetHeight(20)
	end
end

local RAID_TARGET_UPDATE = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
	end
end

local Shared = function(self, unit, isSingle)
	self.menu = addon.menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"AnyUp"

	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetHeight(20)
	Health:SetStatusBarTexture(TEXTURE)

	Health.frequentUpdates = true

	Health:SetPoint"TOP"
	Health:SetPoint"LEFT"
	Health:SetPoint"RIGHT"

	self.Health = Health

	local HealthBackground = Health:CreateTexture(nil, "BORDER")
	HealthBackground:SetAllPoints(self)
	HealthBackground:SetTexture(0, 0, 0, .5)

	Health.bg = HealthBackground

	local HealthPoints = Health:CreateFontString(nil, "OVERLAY")
	HealthPoints:SetPoint("RIGHT", -2, -1)
	HealthPoints:SetFontObject(GameFontNormalSmall)
	HealthPoints:SetTextColor(1, 1, 1)
	self:Tag(HealthPoints, '[dead][offline][lily:health]')

	Health.value = HealthPoints

	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetHeight(2)
	Power:SetStatusBarTexture(TEXTURE)

	Power.frequentUpdates = true
	Power.colorTapping = true
	Power.colorClass = true
	Power.colorReaction = true

	Power:SetPoint"LEFT"
	Power:SetPoint"RIGHT"
	Power:SetPoint("TOP", Health, "BOTTOM")

	self.Power = Power

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
	name:SetPoint("LEFT", RaidIcon, "RIGHT", 0, -5)
	name:SetPoint("RIGHT", PowerPoints, "LEFT")
	name:SetJustifyH"LEFT"
	name:SetFontObject(GameFontNormalSmall)
	name:SetTextColor(1, 1, 1)

	self.Name = name

	local AltPowerBar = CreateFrame("StatusBar", nil, self)
	AltPowerBar:SetHeight(2)
	AltPowerBar:SetStatusBarTexture(TEXTURE)
	AltPowerBar:SetStatusBarColor(1, 1, 1)

	AltPowerBar:SetPoint"LEFT"
	AltPowerBar:SetPoint"RIGHT"
	AltPowerBar:SetPoint("BOTTOM", self.Health, "TOP")

	self.AltPowerBar = AltPowerBar

	if(isSingle) then
		self:SetSize(220, 22)
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
	target = function(self, ...)
		Shared(self, ...)

		local Buffs = CreateFrame("Frame", nil, self)
		Buffs.initialAnchor = "BOTTOMRIGHT"
		Buffs["growth-x"] = "LEFT"
		Buffs:SetPoint("RIGHT", self, "LEFT")

		Buffs:SetHeight(22)
		Buffs:SetWidth(8 * 22)
		Buffs.num = 8
		Buffs.size = 22

		self.Buffs = Buffs

		local Debuffs = CreateFrame("Frame", nil, self)
		Debuffs:SetPoint("LEFT", self, "RIGHT")
		Debuffs.showDebuffType = true
		Debuffs.initialAnchor = "BOTTOMLEFT"

		Debuffs:SetHeight(22)
		Debuffs:SetWidth(8 * 22)
		Debuffs.num = 8
		Debuffs.size = 22

		self.Debuffs = Debuffs

		Debuffs.PostCreateIcon = PostCreateIcon
		Debuffs.PostUpdateIcon = PostUpdateIcon

		Buffs.PostCreateIcon = PostCreateIcon
		Buffs.PostUpdateIcon = PostUpdateIcon
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

		local LFDRole = self:CreateTexture(nil, "OVERLAY")
		LFDRole:SetSize(16, 16)
		LFDRole:SetPoint("RIGHT", self, "LEFT", -3, 0)

		self.LFDRole = LFDRole

		local Health, Power = self.Health, self.Power

		local Buffs = CreateFrame("Frame", nil, self)
		Buffs:SetHeight(22)
		Buffs:SetPoint("LEFT", self, "RIGHT")
		Buffs:SetWidth(2 * 22)
		Buffs.size = 22

		Buffs.CustomFilter = addon.PartyBuffsCustomFilter
		Buffs.PostUpdate = addon.PartyBuffsPostUpdate
		Buffs.PostCreateIcon = PostCreateIcon

		self.Buffs = Buffs

		local Auras = CreateFrame("Frame", nil, self)
		Auras:SetHeight(22)
		Auras:SetPoint("LEFT", Buffs, "RIGHT")

		Auras.showDebuffType = true

		Auras:SetWidth(9 * 22)
		Auras.size = 22
		Auras.gap = true
		Auras.numBuffs = 4
		Auras.numDebuffs = 4

		Auras.CustomFilter = addon.PartyAurasCustomFilter
		Auras.PostCreateIcon = PostCreateIcon

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
	elseif(UnitSpecific[unit:match('[^%d]+')]) then -- boss1 -> boss
		self:SetActiveStyle('Lily - ' .. unit:match('[^%d]+'):gsub("^%l", string.upper))
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

	for n=1, 4 do
		spawnHelper(self,'boss' .. n, 'TOPRIGHT', -10, -155 - (40 * n))
	end

	self:SetActiveStyle'Lily - Party'
	local party = self:SpawnHeader(
		nil, nil, 'raid,party,solo',
		'showParty', true, 'showPlayer', true, 'showSolo', false, 'yOffset', -20,
		'oUF-initialConfigFunction', [[
			self:SetHeight(22)
			self:SetWidth(220)
		]]
	)
	party:SetPoint("TOPLEFT", 30, -30)
end)
