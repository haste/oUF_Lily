--[[-------------------------------------------------------------------------
  Trond A Ekseth grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]

local TEXTURE = [[Interface\AddOns\oUF_Lily\textures\statusbar]]

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("^%l", string.upper)

	if(cunit == 'Vehicle') then
		cunit = 'Pet'
	end

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

local siValue = function(val)
	if(val >= 1e6) then
		return ('%.1f'):format(val / 1e6):gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f"):format(val / 1e3):gsub('%.', 'k')
	else
		return val
	end
end

oUF.Tags['lily:health'] = function(unit)
	if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if(not UnitIsFriend('player', unit)) then
		return siValue(min)
	elseif(min ~= 0 and min ~= max) then
		return '-' .. siValue(max - min)
	else
		return max
	end
end
oUF.TagEvents['lily:health'] = oUF.TagEvents.missinghp

oUF.Tags['lily:power'] = function(unit)
	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if(min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	return siValue(min)
end
oUF.TagEvents['lily:power'] = oUF.TagEvents.missingpp

local updateName = function(self, event, unit)
	if(self.unit == unit) then
		local r, g, b, t
		if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
			r, g, b = .6, .6, .6
		elseif(unit == 'pet') then
			t = self.colors.happiness[GetPetHappiness()]
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
	return updateName(Health:GetParent(), event, unit)
end

local PostCastStart = function(Castbar, unit, spell, spellrank)
	Castbar:GetParent().Name:SetText('×' .. spell)
end

local PostCastStop = function(Castbar, unit)
	local self = Castbar:GetParent()
	self.Name:SetText(UnitName(self.realUnit or unit))
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

local Shared = function(self, unit)
	self.menu = menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetHeight(20)
	Health:SetStatusBarTexture(TEXTURE)
	Health:GetStatusBarTexture():SetHorizTile(false)

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
	Power:GetStatusBarTexture():SetHorizTile(false)

	Power.frequentUpdates = true
	Power.colorTaPowering = true
	Power.colorHaPoweriness = true
	Power.colorClass = true
	Power.colorReaction = true

	Power:SetParent(self)
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
	Castbar:GetStatusBarTexture():SetHorizTile(false)

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

	self:SetAttribute('initial-height', 22)
	self:SetAttribute('initial-width', 220)

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
	pet = function(self)
		Shared(self)

		self:RegisterEvent("UNIT_HAPPINESS", updateName)
	end,

	target = function(self)
		Shared(self)

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
}
UnitSpecific.focus = UnitSpecific.target

do
	local range = {
		insideAlpha = 1,
		outsideAlpha = .5,
	}

	UnitSpecific.party = function(self)
		Shared(self)

		local Health, Power = self.Health, self.Power
		local Auras = CreateFrame("Frame", nil, self)
		Auras:SetHeight(Health:GetHeight() + Power:GetHeight())
		Auras:SetPoint("LEFT", self, "RIGHT")

		Auras.showDebuffType = true

		Auras:SetWidth(9 * 22)
		Auras.size = 22
		Auras.gap = true
		Auras.numBuffs = 4
		Auras.numDebuffs = 4

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
		local object = self:Spawn(unit)
		object:SetPoint(...)
		return object
	else
		self:SetActiveStyle'Lily'
		local object = self:Spawn(unit)
		object:SetPoint(...)
		return object
	end
end

oUF:Factory(function(self)
	local base = 100
	spawnHelper(self, 'focus', "BOTTOM", 0, base + (40 * 1))
	spawnHelper(self, 'pet', 'BOTTOM', 0, base + (40 * 2))
	spawnHelper(self, 'player', 'BOTTOM', 0, base + (40 * 3))
	spawnHelper(self, 'target', 'BOTTOM', 0, base + (40 * 4))
	spawnHelper(self, 'targettarget', 'BOTTOM', 0, base + (40 * 5))

	self:SetActiveStyle'Lily - Party'
	local party = self:SpawnHeader(nil, nil, 'raid,party,solo', 'showParty', true, 'showPlayer', true, 'yOffset', -20)
	party:SetPoint("TOPLEFT", 30, -30)
end)
