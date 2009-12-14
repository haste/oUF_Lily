--[[-------------------------------------------------------------------------
  Trond A Ekseth grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]

local TEXTURE = [[Interface\AddOns\oUF_Lily\textures\statusbar]]

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

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

local OverrideUpdateHealth = function(self, event, unit, bar, min, max)
	if(UnitIsDead(unit)) then
		bar:SetValue(0)
		bar.value:SetText"Dead"
	elseif(UnitIsGhost(unit)) then
		bar:SetValue(0)
		bar.value:SetText"Ghost"
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText"Offline"
	else
		if(not UnitIsFriend('player', unit)) then
			bar.value:SetFormattedText('%s', siValue(min))
		elseif(min ~= 0 and min ~= max) then
			bar.value:SetFormattedText("-%s", siValue(max - min))
		else
			bar.value:SetText(max)
		end
	end

	bar:SetStatusBarColor(.25, .25, .35)
	return updateName(self, event, unit)
end

local PostCastStart = function(self, event, unit, spell, spellrank, castid)
	self.Name:SetText('×' .. spell)
end

local PostCastStop = function(self, event, unit)
	-- Needed as we use it as a general update function.
	if(unit ~= self.unit) then return end
	self.Name:SetText(UnitName(unit))
end

local PostCreateAuraIcon = function(self, button)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint"BOTTOM"

	button.icon:SetTexCoord(.07, .93, .07, .93)
end

local PostUpdateAuraIcon
do
	local playerUnits = {
		player = true,
		pet = true,
		vehicle = true,
	}

	PostUpdateAuraIcon = function(self, icons, unit, icon, index, offset, filter, isDebuff)
		local texture = icon.icon
		if(playerUnits[icon.owner]) then
			texture:SetDesaturated(false)
		else
			texture:SetDesaturated(true)
		end
	end
end

local CustomAuraFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
	local isPlayer

	if(caster == 'player' or caster == 'vehicle') then
		isPlayer = true
	end

	if((icons.onlyShowPlayer and isPlayer) or (not icons.onlyShowPlayer and name)) then
		icon.isPlayer = isPlayer
		icon.owner = caster

		-- We set it to math.huge, because it lasts until cancelled.
		if(timeLeft == 0) then
			icon.timeLeft = math.huge
		else
			icon.timeLeft = timeLeft
		end

		return true
	end
end

local sort = function(a, b)
	return a.timeLeft > b.timeLeft
end

local PreAuraSetPosition = function(self, auras, max)
	table.sort(auras, sort)
end

local PostUpdatePower = function(self, event, unit, bar, min, max)
	self.Health:SetHeight(22)
	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		bar.value:SetText()
		bar:SetValue(0)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	else
		self.Health:SetHeight(20)
		bar.value:SetFormattedText("%s | ", siValue(min))
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
	player = function(self)
		self.Runes = CreateFrame('Frame', nil, self)
		self.Runes:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -1)
		self.Runes:SetHeight(7)
		self.Runes:SetWidth(230)
		self.Runes.anchor = "TOPLEFT"
		self.Runes.growth = "RIGHT"
		self.Runes.height = 7
		self.Runes.width = 230 / 6 - 0.85

		for i = 1, 6 do
			self.Runes[i] = CreateFrame("StatusBar", nil, self.Runes)
			self.Runes[i]:SetStatusBarTexture(TEXTURE)
		end

	end,
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

		self.CustomAuraFilter = CustomAuraFilter
		self.PreAuraSetPosition = PreAuraSetPosition

		self.PostUpdateAuraIcon = PostUpdateAuraIcon
	end,

	party = function(self)
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

		self.Auras = auras

		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end,
}
UnitSpecific.focus = UnitSpecific.target

local Shared = function(self, unit)
	self.menu = menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetHeight(20)
	hp:SetStatusBarTexture(TEXTURE)

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

	hp.value = hpp

	local pp = CreateFrame("StatusBar", nil, self)
	pp:SetHeight(2)
	pp:SetStatusBarTexture(TEXTURE)

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

	pp.value = ppp

	local cb = CreateFrame("StatusBar", nil, self)
	cb:SetStatusBarTexture(TEXTURE)
	cb:SetStatusBarColor(1, .25, .35, .5)
	cb:SetAllPoints(hp)
	cb:SetToplevel(true)

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

	-- We inject our fake name element early in the cycle, in-case there is a
	-- spell cast in progress on the unit we target.
	self:RegisterEvent('UNIT_NAME_UPDATE', PostCastStop)
	table.insert(self.__elements, 2, PostCastStop)

	self.PostChannelStart = PostCastStart
	self.PostCastStart = PostCastStart

	self.PostCastStop = PostCastStop
	self.PostChannelStop = PostCastStop

	self.PostCreateAuraIcon = PostCreateAuraIcon

	self.PostUpdatePower = PostUpdatePower

	self.OverrideUpdateHealth = OverrideUpdateHealth

	-- Small hack are always allowed...
	local unit = unit or 'party'
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
oUF:SetActiveStyle"Lily"

-- :Spawn(unit, frame_name, isPet) --isPet is only used on headers.
oUF:Spawn"focus":SetPoint("CENTER", 0, -500)
oUF:Spawn'pet':SetPoint('CENTER', 0, -450)
oUF:Spawn"player":SetPoint("CENTER", 0, -400)
oUF:Spawn"target":SetPoint("CENTER", 0, -351)
oUF:Spawn"targettarget":SetPoint("CENTER", 0, -300)

local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("TOPLEFT", 30, -30)
party:SetManyAttributes("showParty", true, 'showPlayer', true, "yOffset", -25)
party:Show()
