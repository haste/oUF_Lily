local name, addon = ...

-- Party
do
	local prioTable = {
		[GetSpellInfo(139)] = 1, -- Renew
		[GetSpellInfo(33076)] = 2, -- Prayer of Mending
	}

	local PartyBuffsCustomFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
		if(caster == 'player' and prioTable[name]) then
			return true
		end
	end

	local PartyBuffsPostUpdate = function(buffs)
		local parent = buffs:GetParent()
		local vb = buffs.visibleBuffs
		if(vb > 0) then
			parent.Auras:ClearAllPoints()
			parent.Auras:SetPoint('LEFT', parent, 'RIGHT', (vb+1) * (buffs.size + 4), 0)
		else
			parent.Auras:ClearAllPoints()
			parent.Auras:SetPoint('LEFT', parent, 'RIGHT', 4, 0)
		end
	end

	local PartyAurasCustomFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
		if(caster == 'player' and prioTable[name]) then
			return
		end

		return true
	end

	addon.PartyAurasCustomFilter = PartyAurasCustomFilter
	addon.PartyBuffsPostUpdate = PartyBuffsPostUpdate
	addon.PartyBuffsCustomFilter = PartyBuffsCustomFilter
end
