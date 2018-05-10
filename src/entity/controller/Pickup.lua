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
		love.graphics.circle("line", x, y, 6, 16)
		love.graphics.circle("fill", x, y, 3, 16)
		love.graphics.setFont(main.font.game)
		love.graphics.printf(self.weapon.fullname,x-128,y+8,256,"center")
	else
		love.graphics.circle("line", x, y, 6, 16)
		local cs,cw = 6,2
		love.graphics.rectangle("fill", x-cw/2, y-cs/2, cw, cs)
		love.graphics.rectangle("fill", x-cs/2, y-cw/2, cs, cw)
	end
end

return Pickup
