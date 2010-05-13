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

local PostUpdateHealth = function(health, unit, min, max)
	if(UnitIsDead(unit)) then
		health:SetValue(0)
	elseif(UnitIsGhost(unit)) then
		health:SetValue(0)
	end

	health:SetStatusBarColor(.25, .25, .35)
	return updateName(health:GetParent(), event, unit)
end

local PostCastStart = function(castbar, unit, spell, spellrank)
	castbar:GetParent().Name:SetText('×' .. spell)
end

local PostCastStop = function(castbar, unit)
	local self = castbar:GetParent()
	self.Name:SetText(UnitName(self.realUnit or unit))
end

local PostCastStopUpdate = function(self, event, unit)
	if(unit ~= self.unit) then return end
	return PostCastStop(self.Castbar, unit)
end

local PostCreateIcon = function(auras, button)
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

local PostUpdatePower = function(power, unit, min, max)
	local health = power:GetParent().Health
	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		power:SetValue(0)
		health:SetHeight(22)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		power:SetValue(0)
		health:SetHeight(22)
	else
		health:SetHeight(20)
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

local UnitSpecific = {
	pet = function(self)
		self:RegisterEvent("UNIT_HAPPINESS", updateName)
	end,

	target = function(self)
		local buffs = CreateFrame("Frame", nil, self)
		buffs.initialAnchor = "BOTTOMRIGHT"
		buffs["growth-x"] = "LEFT"
		buffs:SetPoint("RIGHT", self, "LEFT")

		buffs:SetHeight(22)
		buffs:SetWidth(8 * 22)
		buffs.num = 8
		buffs.size = 22

		self.Buffs = buffs

		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetPoint("LEFT", self, "RIGHT")
		debuffs.showDebuffType = true
		debuffs.initialAnchor = "BOTTOMLEFT"

		debuffs:SetHeight(22)
		debuffs:SetWidth(8 * 22)
		debuffs.num = 8
		debuffs.size = 22

		self.Debuffs = debuffs

		debuffs.PostCreateIcon = PostCreateIcon
		debuffs.PostUpdateIcon = PostUpdateIcon

		buffs.PostCreateIcon = PostCreateIcon
		buffs.PostUpdateIcon = PostUpdateIcon
	end,
}
UnitSpecific.focus = UnitSpecific.target

do
	local range = {
		insideAlpha = 1,
		outsideAlpha = .5,
	}

	UnitSpecific.party = function(self)
		local hp, pp = self.Health, self.Power
		local auras = CreateFrame("Frame", nil, self)
		auras:SetHeight(hp:GetHeight() + pp:GetHeight())
		auras:SetPoint("LEFT", self, "RIGHT")

		auras.showDebuffType = true

		auras:SetWidth(9 * 22)
		auras.size = 22
		auras.gap = true
		auras.numBuffs = 4
		auras.numDebuffs = 4

		auras.PostCreateIcon = PostCreateIcon

		self.Auras = auras

		self.Range = range
	end
end

local Shared = function(self, unit)
	self.menu = menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetHeight(20)
	hp:SetStatusBarTexture(TEXTURE)
	hp:GetStatusBarTexture():SetHorizTile(false)

	hp.frequentUpdates = true

	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"

	self.Health = hp

	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(self)
	hpbg:SetTexture(0, 0, 0, .5)

	hp.bg = hpbg

	local hpp = hp:CreateFontString(nil, "OVERLAY")
	hpp:SetPoint("RIGHT", -2, -1)
	hpp:SetFontObject(GameFontNormalSmall)
	hpp:SetTextColor(1, 1, 1)
	self:Tag(hpp, '[dead][offline][lily:health]')

	hp.value = hpp

	local pp = CreateFrame("StatusBar", nil, self)
	pp:SetHeight(2)
	pp:SetStatusBarTexture(TEXTURE)
	pp:GetStatusBarTexture():SetHorizTile(false)

	pp.frequentUpdates = true
	pp.colorTapping = true
	pp.colorHappiness = true
	pp.colorClass = true
	pp.colorReaction = true

	pp:SetParent(self)
	pp:SetPoint"LEFT"
	pp:SetPoint"RIGHT"
	pp:SetPoint("TOP", hp, "BOTTOM")

	self.Power = pp

	local ppp = pp:CreateFontString(nil, "OVERLAY")
	ppp:SetPoint("RIGHT", hpp, "LEFT", 0, 0)
	ppp:SetFontObject(GameFontNormalSmall)
	ppp:SetTextColor(1, 1, 1)
	self:Tag(ppp, '[lily:power< | ]')

	pp.value = ppp

	local cb = CreateFrame("StatusBar", nil, self)
	cb:SetStatusBarTexture(TEXTURE)
	cb:SetStatusBarColor(1, .25, .35, .5)
	cb:SetAllPoints(hp)
	cb:SetToplevel(true)
	cb:GetStatusBarTexture():SetHorizTile(false)

	self.Castbar = cb

	local leader = self:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(16)
	leader:SetWidth(16)
	leader:SetPoint("BOTTOM", hp, "TOP", 0, -5)

	self.Leader = leader

	local masterlooter = self:CreateTexture(nil, 'OVERLAY')
	masterlooter:SetHeight(16)
	masterlooter:SetWidth(16)
	masterlooter:SetPoint('LEFT', leader, 'RIGHT')

	self.MasterLooter = masterlooter

	local ricon = hp:CreateFontString(nil, "OVERLAY")
	ricon:SetPoint("LEFT", 2, 4)
	ricon:SetJustifyH"LEFT"
	ricon:SetFontObject(GameFontNormalSmall)
	ricon:SetTextColor(1, 1, 1)

	self.RIcon = ricon
	self:RegisterEvent("RAID_TARGET_UPDATE", RAID_TARGET_UPDATE)
	table.insert(self.__elements, RAID_TARGET_UPDATE)

	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", ricon, "RIGHT", 0, -5)
	name:SetPoint("RIGHT", ppp, "LEFT")
	name:SetJustifyH"LEFT"
	name:SetFontObject(GameFontNormalSmall)
	name:SetTextColor(1, 1, 1)

	self.Name = name

	self:SetAttribute('initial-height', 22)
	self:SetAttribute('initial-width', 220)

	self:RegisterEvent('UNIT_NAME_UPDATE', PostCastStopUpdate)
	table.insert(self.__elements, PostCastStopUpdate)

	cb.PostChannelStart = PostCastStart
	cb.PostCastStart = PostCastStart

	cb.PostCastStop = PostCastStop
	cb.PostChannelStop = PostCastStop

	hp.PostUpdate = PostUpdateHealth
	pp.PostUpdate = PostUpdatePower

	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end

oUF:RegisterStyle("Lily", Shared)

--[[
-- oUF does to this for, but only for the first layout registered. I'm mainly
-- adding it here so people know about it, especially since it's required for
-- layouts using different styles between party/partypet/raid/raidpet. It is
-- however smart to execute this function regardless.
--
-- There is a possibility that another layout has been registered before yours.
--]]

oUF:Factory(function(self)
	self:SetActiveStyle"Lily"

	local base = 100
	self:Spawn"focus":SetPoint("BOTTOM", 0, base + (40 * 1))
	self:Spawn'pet':SetPoint('BOTTOM', 0, base + (40 * 2))
	self:Spawn"player":SetPoint("BOTTOM", 0, base + (40 * 3))
	self:Spawn"target":SetPoint("BOTTOM", 0, base + (40 * 4))
	self:Spawn"targettarget":SetPoint("BOTTOM", 0, base + (40 * 5))

	local party = self:SpawnHeader(nil, nil, 'raid,party,solo', 'showParty', true, 'showPlayer', true--[[, 'showSolo', true]], 'yOffset', -20)
	party:SetPoint("TOPLEFT", 30, -30)
end)
