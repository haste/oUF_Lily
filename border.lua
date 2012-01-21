local name, addon = ...

local bnot, band = bit.bnot, bit.band
local flags = {}
for i=0, 7 do
	flags[i] = bit.lshift(1, i)
end

local methods = {
	Hide = function(self)
		if(not self.__visible) then return end

		for i=1,8 do
			self[i]:Hide()
		end

		self.__visible = nil
	end,

	Show = function(self)
		if(self.__visible) then return end

		for i=1,8 do
			self[i]:Show()
		end

		self.__visible = true
	end,

	SetColor = function(self, r, g, b, a)
		if(r == self.__r and g == self.__g and b == self.__b and a == self.__a) then
			return
		end

		for i=1,8 do
			self[i]:SetVertexColor(r, g, b, a)
		end

		self.__r, self.__g, self.__b, self.__a = r, g, b, a
	end,

	SetParent = function(self, parent)
		self.__parent = parent
	end,

	SetVisible = function(self, left, right, top, bottom)
		local mask = 0xff
		if(not left) then
			mask = mask - flags[0]
			mask = band(mask, bnot(flags[1]))
			mask = band(mask, bnot(flags[7]))
		end

		if(not right) then
			mask = mask - flags[4]
			mask = band(mask, bnot(flags[3]))
			mask = band(mask, bnot(flags[5]))
		end

		if(not top) then
			mask = mask - flags[2]
			mask = band(mask, bnot(flags[1]))
			mask = band(mask, bnot(flags[3]))
		end

		if(not bottom) then
			mask = mask - flags[6]
			mask = band(mask, bnot(flags[7]))
			mask = band(mask, bnot(flags[5]))
		end

		for i=0, 7 do
			if(band(mask, flags[i]) ~= 0) then
				self[i + 1]:Show()
			else
				self[i + 1]:Hide()
			end
		end
	end,

	SetPoint = function(self, point)
		point = point or self.__parent

		for i=1, 8 do
			self[i]:ClearAllPoints()
		end

		local Left = self[1]
		Left:SetPoint('RIGHT', point, 'LEFT')
		Left:SetPoint('TOP')
		Left:SetPoint('BOTTOM')
		Left:SetWidth(16)

		local TopLeft = self[2]
		TopLeft:SetPoint('BOTTOMRIGHT', point, 'TOPLEFT')
		TopLeft:SetSize(16, 16)

		local Top = self[3]
		Top:SetPoint('BOTTOM', point, 'TOP')
		Top:SetPoint('LEFT')
		Top:SetPoint('RIGHT')
		Top:SetHeight(16)

		local TopRight = self[4]
		TopRight:SetPoint('BOTTOMLEFT', point, 'TOPRIGHT')
		TopRight:SetSize(16, 16)

		local Right = self[5]
		Right:SetPoint('LEFT', point, 'RIGHT')
		Right:SetPoint('TOP')
		Right:SetPoint('BOTTOM')
		Right:SetWidth(16)

		local BottomRight = self[6]
		BottomRight:SetPoint('TOPLEFT', point, 'BOTTOMRIGHT')
		BottomRight:SetSize(16, 16)

		local Bottom = self[7]
		Bottom:SetPoint('TOP', point, 'BOTTOM')
		Bottom:SetPoint('LEFT')
		Bottom:SetPoint('RIGHT')

		local BottomLeft = self[8]
		BottomLeft:SetPoint('TOPRIGHT', point, 'BOTTOMLEFT')
		BottomLeft:SetSize(16, 16)
	end
}
methods.__index = methods

function addon.CreateBorder(self, texture)
	local Border = setmetatable({
		__visible = true,
	}, methods)

	for i=1,8 do
		local T = self:CreateTexture(nil, 'BORDER')
		T:SetTexture(texture)
		Border[i] = T
	end

	local Left = Border[1]
	Left:SetTexCoord(0/8, 1/8, 0/8, 8/8)

	local TopLeft = Border[2]
	TopLeft:SetTexCoord(6/8, 7/8, 8/8, 0/8)

	-- Affine transofrmation matrix used
	-- {{cos(90), sin(90), 1}, {-sin(90), cos(90), 1}, {0, 0, 1}} *
	-- {{32, 0,  -11}, {0, 1, 0}, {0, 0, 1}}
	local Top = Border[3]
	Top:SetTexCoord(.5, -.75, .375, -.75, .5, -.625, .375, -.625)

	local TopRight = Border[4]
	TopRight:SetTexCoord(7/8, 6/8, 8/8, 0/8)

	local Right = Border[5]
	Right:SetTexCoord(1/8, 0/8, 0/8, 8/8)

	local BottomRight = Border[6]
	BottomRight:SetTexCoord(5/8, 6/8, 8/8, 0/8)

	-- Affine transofrmation matrix used
	-- {{cos(90), -sin(90), 1}, {sin(90), cos(90), 0}, {0, 0, 1}} *
	-- {{8, 0,  -3}, {0, 1, 0}, {0, 0, 1}}
	local Bottom = Border[7]
	Bottom:SetTexCoord(.375, 1, .5, 1, .375, 0, .5, 0)

	local BottomLeft = Border[8]
	BottomLeft:SetTexCoord(6/8, 5/8, 8/8, 0/8)

	Border:SetParent(self)
	Border:SetPoint()

	self.Border = Border
	return Border
end
