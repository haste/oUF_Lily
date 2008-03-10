--[[-------------------------------------------------------------------------
  Trond A Ekseth grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]

local select = select
local UnitIsPlayer = UnitIsPlayer
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsConnected = UnitIsConnected
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitClass = UnitClass
local UnitReactionColor = UnitReactionColor
local UnitReaction = UnitReaction

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
	if(self.unit ~= unit) then return end

	local name = UnitName(unit)
	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self.Name:SetTextColor(.6, .6, .6)	
	else
		local color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or UnitReactionColor[UnitReaction(unit, "player")]
		if(color) then self.Name:SetTextColor(color.r, color.g, color.b) end
	end

	self.Name:SetText(name)
end

local updateHealth = function(self, event, bar, unit, min, max)
	if(UnitIsDead(unit)) then
		bar:SetValue(0)
		bar.value:SetText"Dead"
	elseif(UnitIsGhost(unit)) then
		bar:SetValue(0)
		bar.value:SetText"Ghost"
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText"Offline"
	else
		local c = max - min
		if(c > 0) then
			bar.value:SetFormattedText("-%d", c)
		else
			bar.value:SetText(max)
		end
	end

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self.Name:SetTextColor(.6, .6, .6)
		self.Power:SetStatusBarColor(.6, .6, .6)
	else
		self:UNIT_NAME_UPDATE(event, unit)
	end
end

local updatePower = function(self, event, bar, unit, min, max)
	if(min == 0) then
		bar.value:SetText()
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText()
	else
		bar.value:SetFormattedText("%d | ", min)
	end

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		bar:SetStatusBarColor(.6, .6, .6)
	else
		local color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or UnitReactionColor[UnitReaction(unit, "player")]
		if(color) then bar:SetStatusBarColor(color.r, color.g, color.b) end
	end
end

local auraIcon = function(self, button)
	button.icon:SetTexCoord(.07, .93, .07, .93)
end

local func = function(settings, self, unit)
	self.menu = menu

	self:EnableMouse(true)
	self:SetMovable(true)

	self:SetHeight(22)
	self:SetWidth(200)

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:SetScript("OnMouseDown", function(self) if(IsAltKeyDown()) then self:StartMoving() end end)
	self:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	local hp = CreateFrame"StatusBar"
	hp:SetHeight(20)
	hp:SetStatusBarTexture"Interface\\AddOns\\oUF_Lily\\textures\\statusbar"
	hp:SetStatusBarColor(.25, .25, .35)

	hp:SetParent(self)
	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"

	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
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
	pp:SetStatusBarColor(.25, .25, .35)

	pp:SetParent(self)
	pp:SetPoint"LEFT"
	pp:SetPoint"RIGHT"
	pp:SetPoint("TOP", hp, "BOTTOM")

	local ppbg = pp:CreateTexture(nil, "BORDER")
	ppbg:SetAllPoints(pp)
	ppbg:SetTexture(0, 0, 0, .5)

	local ppp = pp:CreateFontString(nil, "OVERLAY")
	ppp:SetPoint("RIGHT", hpp, "LEFT", 0, 0)
	ppp:SetFontObject(GameFontNormalSmall)
	ppp:SetTextColor(1, 1, 1)

	pp.value = ppp
	pp.bg = ppbg
	self.Power = pp
	self.OverrideUpdatePower = updatePower

	local leader = self:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(16)
	leader:SetWidth(16)
	leader:SetPoint("BOTTOM", hp, "TOP", 0, -5)
	leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
	self.Leader = leader

	local ricon = self:CreateTexture(nil, "OVERLAY")
	ricon:SetHeight(16)
	ricon:SetWidth(16)
	ricon:SetPoint("RIGHT", self, "LEFT")
	ricon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	self.RaidIcon = ricon

	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", 2, -1)
	name:SetPoint("RIGHT", ppp, "LEFT")
	name:SetJustifyH"LEFT"
	name:SetFontObject(GameFontNormalSmall)
	name:SetTextColor(1, 1, 1)
	self.Name = name
	self.UNIT_NAME_UPDATE = updateName

	if(not unit or unit == "target") then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetHeight(hp:GetHeight() + pp:GetHeight())
		buffs:SetWidth(10*self:GetHeight())
		if(not unit) then
			buffs.initialAnchor = "BOTTOMLEFT"
			buffs.num = 4
			buffs:SetPoint("LEFT", self, "RIGHT")
		else
			buffs.initialAnchor = "BOTTOMRIGHT"
			buffs.num = 8
			buffs["growth-x"] = "LEFT"
			buffs:SetPoint("RIGHT", self, "LEFT")
		end
		buffs.size = math.floor(buffs:GetHeight() + .5)
		self.Buffs = buffs
	end

	if(unit and not (unit == "targettarget" or unit == "player")) then
		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetHeight(hp:GetHeight() + pp:GetHeight())
		debuffs:SetWidth(10*self:GetHeight())
		debuffs:SetPoint("LEFT", self, "RIGHT")
		debuffs.size = math.floor(debuffs:GetHeight() + .5)
		debuffs.initialAnchor = "BOTTOMLEFT"
		debuffs.num = 8
		self.Debuffs = debuffs
	end

	if(not unit) then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

	self.PostCreateAuraIcon = auraIcon

	return self
end

oUF:RegisterStyle("Lily", setmetatable({
	["party-yOffset"] = -25,

	["initial-width"] = 200,
	["initial-height"] = 22,
}, {__call = func}))

local focus = oUF:Spawn"focus"
focus:SetPoint("CENTER", 0, -450)
local player = oUF:Spawn"player"
player:SetPoint("CENTER", 0, -400)
local target = oUF:Spawn"target"
target:SetPoint("CENTER", 0, -351)
local tot = oUF:Spawn"targettarget"
tot:SetPoint("CENTER", 0, -300)
local party = oUF:Spawn"party"
party:SetPoint("TOPLEFT", 30, -30)
