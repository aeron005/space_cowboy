local Component = require('classes.Component')
local Pickup = Component:extend("Pickup")

local color = require('util.color')

function Pickup:init(contents)
	self.level = 0
	for k,v in pairs(contents or {}) do
		self[k] = v
	end
end

function Pickup.on:draw(e)
	local x,y = math.floor(e.x), math.floor(e.y)
	love.graphics.setColor(color.level(self.level))
	love.graphics.circle("line", x, y, 4, 16)
	love.graphics.circle("fill", x, y, 2, 16)

	if self.weapon then
		if not self.title then
			self.title = "L"..math.floor(self.weapon.level).." "..self.weapon.display
		end
		love.graphics.setFont(main.font.game)
		love.graphics.printf(self.title,x-128,y+6,256,"center")
	end
end

return Pickup
