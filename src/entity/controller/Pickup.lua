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

	if self.weapon then
		love.graphics.circle("line", x, y, 4, 16)
		love.graphics.circle("fill", x, y, 2, 16)
		love.graphics.setFont(main.font.game)
		love.graphics.printf(self.weapon.fullname,x-128,y+6,256,"center")
	else
		love.graphics.circle("line", x, y, 4, 16)
		love.graphics.rectangle("fill", x-1, y-4, 2, 8)
		love.graphics.rectangle("fill", x-4, y-1, 8, 2)
	end
end

return Pickup
