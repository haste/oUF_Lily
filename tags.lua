local siValue = function(val)
	if(val >= 1e6) then
		return ('%.1f'):format(val / 1e6):gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f"):format(val / 1e3):gsub('%.', 'k')
	else
		return val
	end
end

local tags = oUF.Tags.Methods or oUF.Tags
local tagevents = oUF.TagEvents or oUF.Tags.Events

tags['lily:health'] = function(unit)
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
tagevents['lily:health'] = tagevents.missinghp

tags['lily:power'] = function(unit)
	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if(min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	return siValue(min)
end
tagevents['lily:power'] = tagevents.missingpp
