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

local updateName = function(self, unit)
	if(self.unit ~= unit) then return end

	local name = UnitName(unit)
	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self.Name:SetTextColor(.6, .6, 6)	
	else
		local color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or UnitReactionColor[UnitReaction(unit, "player")]
		if(color) then self.Name:SetTextColor(color.r, color.g, color.b) end
	end

	self.Name:SetText(name)
end

local updateHealth = function(self, object, unit, min, max)
	if(UnitIsDead(unit)) then
		self:SetValue(0)
		self.value:SetText"Dead"
	elseif(UnitIsGhost(unit)) then
		self:SetValue(0)
		self.value:SetText"Ghost"
	elseif(not UnitIsConnected(unit)) then
		self.value:SetText"Offline"
	else
		local c = max - min
		if(c > 0) then
			self.value:SetFormattedText("-%d", c)
		else
			self.value:SetText(max)
		end
	end

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		object.Name:SetTextColor(.6, .6, .6)
		object.Power:SetStatusBarColor(.6, .6, .6)
	else
		object:UpdateName(unit)
	end
end

local updatePower = function(self, object, unit, min, max)
	if(min == 0) then
		self.value:SetText()
	elseif(UnitIsDead(unit)) then
		self:SetValue(0)
	elseif(UnitIsGhost(unit)) then
		self:SetValue(0)
	else
		local c = max - min
		if(c > 0) then
			self.value:SetText(("-%d | "):format(c))
		else
			self.value:SetText(max.." | ")
		end
	end

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self:SetStatusBarColor(.6, .6, .6)
	else
		local color = UnitIsPlayer(unit) and RAID_CLASS_COLORS[select(2, UnitClass(unit))] or UnitReactionColor[UnitReaction(unit, "player")]
		if(color) then self:SetStatusBarColor(color.r, color.g, color.b) end
	end
end

local func = function(settings, self, unit)
	self.numBuffs = 16
	self.menu = menu
	self.numDebuffs = 8

	self:EnableMouse(true)
	self:SetMovable(true)

	self:SetHeight(28)
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

	hp.func = updateHealth
	hp.bg = hpbg
	hp.value = hpp
	self.Health = hp

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

	pp.func = updatePower
	pp.value = ppp
	pp.bg = ppbg
	self.Power = pp

	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", 2, -1)
	name:SetPoint("RIGHT", ppp, "LEFT")
	name:SetJustifyH"LEFT"
	name:SetFontObject(GameFontNormalSmall)
	name:SetTextColor(1, 1, 1)
	self.Name = name
	self.UpdateName = updateName

	if(unit and unit == "target") then
		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetHeight(self:GetHeight())
		debuffs:SetWidth(30)
		debuffs:SetPoint("LEFT", self, "RIGHT")
		debuffs.size = 22
		self.Debuffs = debuffs
	end

	return self
end

oUF:RegisterStyle("Lily", setmetatable({
	point = "BOTTOM",
	sortDir = "DESC",
	yOffset = 25,
	["initial-width"] = 200,
	["initial-height"] = 28,
}, {__call = func}))

local player = oUF:Spawn"player"
player:SetPoint("CENTER", 0, -400) -- damn 1px issue
local target = oUF:Spawn"target"
target:SetPoint("CENTER", 0, -350)
local tot = oUF:Spawn"targettarget"
tot:SetPoint("CENTER", 0, -300)
local party = oUF:Spawn"party"
party:SetPoint("TOPLEFT", 30, -30)
