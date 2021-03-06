local Component = require('classes.Component')
local Physical = Component:extend("Physical")

function Physical:init(properties)
	if properties then
		for k,v in pairs(properties) do
			self[k] = v
		end
	end
end

local collides = function (e, oe)
	if not oe.Physical 
	or e == oe
	then return false end
	
	local r = e.radius+oe.radius
	if e.x-oe.x>r 
	or oe.x-e.x>r
	or e.y-oe.y>r
	or oe.y-e.y>r
	then return false end
	
	local dx, dy = e.x-oe.x, e.y-oe.y
	return math.sqrt(dx*dx + dy*dy) < r
end

function Physical.on:create(e)
	e.dx, e.dy = 0, 0
	e.radius = 4
	e.collides = collides
end

function Physical.on:update(e, dt)
	local oex, oey = e.x, e.y
	e.x = e.x + dt*e.dx
	e.y = e.y + dt*e.dy

	if self.bounded and e.game then
		local g = e.game
		if e.x - e.radius < g.bounds.x
		or e.x + e.radius > g.bounds.x + g.bounds.w then
			e.x = oex
		end
		if e.y - e.radius < g.bounds.y
		or e.y + e.radius > g.bounds.y + g.bounds.h then
			e.y = oey
		end
	end

	if self.friction then
		e.dx = e.dx * self.friction
		e.dy = e.dy * self.friction
	end
end

return Physical
