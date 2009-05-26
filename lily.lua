--[[-------------------------------------------------------------------------
  Trond A Ekseth grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]

local height, width = 22, 220

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
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

local updateRIcon = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
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

local PostCastStart = function(self, event, unit, spell, spellrank, castid)
	self.Name:SetText('×' .. spell)
end

local PostCastStop = function(self, event, unit)
	-- Needed as we use it as a general update function.
	if(unit ~= self.unit) then return end
	self.Name:SetText(UnitName(unit))
end

local updateHealth = function(self, event, unit, bar, min, max)
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
	updateName(self, event, unit)
end

local updatePower = function(self, event, unit, bar, min, max)
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

local auraIcon = function(self, button)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint"BOTTOM"

	button.icon:SetTexCoord(.07, .93, .07, .93)
end

local func = function(self, unit)
	self.menu = menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	local hp = CreateFrame"StatusBar"
	hp:SetHeight(20)
	hp:SetStatusBarTexture"Interface\\AddOns\\oUF_Lily\\textures\\statusbar"

	hp.frequentUpdates = true

	hp:SetParent(self)
	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"

	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(self)
	hpbg:SetTexture(0, 0, 0, .5)

	local hpp = hp:CreateFontString(nil, "OVERLAY")
	hpp:SetPoint("RIGHT", -2, -1)
	hpp:SetFontObject(GameFontNormalSmall)
	hpp:SetTextColor(1, 1, 1)

	hp.bg = hpbg
	hp.value = hpp
	self.Health = hp
	self.OverrideUpdateHealth = updateHealth

	local pp = CreateFrame"StatusBar"
	pp:SetHeight(2)
	pp:SetStatusBarTexture"Interface\\AddOns\\oUF_Lily\\textures\\statusbar"

	pp.frequentUpdates = true
	pp.colorTapping = true
	pp.colorHappiness = true
	pp.colorClass = true
	pp.colorReaction = true

	pp:SetParent(self)
	pp:SetPoint"LEFT"
	pp:SetPoint"RIGHT"
	pp:SetPoint("TOP", hp, "BOTTOM")

	local ppp = pp:CreateFontString(nil, "OVERLAY")
	ppp:SetPoint("RIGHT", hpp, "LEFT", 0, 0)
	ppp:SetFontObject(GameFontNormalSmall)
	ppp:SetTextColor(1, 1, 1)

	pp.value = ppp
	self.Power = pp
	self.PostUpdatePower = updatePower

	local cb = CreateFrame"StatusBar"
	cb:SetStatusBarTexture"Interface\\AddOns\\oUF_Lily\\textures\\statusbar"
	cb:SetStatusBarColor(1, .25, .35, .5)
	cb:SetParent(self)
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
	self:RegisterEvent("RAID_TARGET_UPDATE", updateRIcon)
	table.insert(self.__elements, updateRIcon)

	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", ricon, "RIGHT", 0, -5)
	name:SetPoint("RIGHT", ppp, "LEFT")
	name:SetJustifyH"LEFT"
	name:SetFontObject(GameFontNormalSmall)
	name:SetTextColor(1, 1, 1)

	self.Name = name

	if(not unit) then
		local auras = CreateFrame("Frame", nil, self)
		auras:SetHeight(hp:GetHeight() + pp:GetHeight())
		auras:SetWidth(9*height)
		auras:SetPoint("LEFT", self, "RIGHT")

		auras.showDebuffType = true
		auras.size = height
		auras.gap = true
		auras.numBuffs = 4
		auras.numDebuffs = 4
		self.Auras = auras
	end

	if(unit == "target") then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetHeight(height)
		buffs:SetWidth(8*height)
		buffs.initialAnchor = "BOTTOMRIGHT"
		buffs.num = 8
		buffs["growth-x"] = "LEFT"
		buffs:SetPoint("RIGHT", self, "LEFT")
		buffs.size = height
		self.Buffs = buffs
	end

	if(unit and not (unit == "targettarget" or unit == "player")) then
		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetHeight(height)
		debuffs:SetWidth(10*height)
		debuffs:SetPoint("LEFT", self, "RIGHT")

		debuffs.showDebuffType = true
		debuffs.size = height
		debuffs.initialAnchor = "BOTTOMLEFT"
		debuffs.num = 8
		self.Debuffs = debuffs
	end

	if(unit == 'pet') then
		self:RegisterEvent("UNIT_HAPPINESS", updateName)
	end

	if(not unit) then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

	self:SetAttribute('initial-height', height)
	self:SetAttribute('initial-width', width)


	-- We inject our fake name element early in the cycle, in-case there is a
	-- spell cast in progress on the unit we target.
	self:RegisterEvent('UNIT_NAME_UPDATE', PostCastStop)
	table.insert(self.__elements, 2, PostCastStop)

	self.PostChannelStart = PostCastStart
	self.PostCastStart = PostCastStart

	self.PostCastStop = PostCastStop
	self.PostChannelStop = PostCastStop

	self.PostCreateAuraIcon = auraIcon
end

oUF:RegisterStyle("Lily", func)

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
local focus = oUF:Spawn"focus"
focus:SetPoint("CENTER", 0, -500)
local pet = oUF:Spawn'pet'
pet:SetPoint('CENTER', 0, -450)
local player = oUF:Spawn"player"
player:SetPoint("CENTER", 0, -400)
local target = oUF:Spawn"target"
target:SetPoint("CENTER", 0, -351)
local tot = oUF:Spawn"targettarget"
tot:SetPoint("CENTER", 0, -300)
local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("TOPLEFT", 30, -30)
party:SetManyAttributes("showParty", true, 'showPlayer', true, "yOffset", -25)
party:Show()
