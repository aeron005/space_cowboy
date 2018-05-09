local Component = require('classes.Component')
local Explosion = Component:extend("Explosion")

local color = require('util.color')

function Explosion:init()
	self.time = 0
	self.max_time = 2

	self.system = love.graphics.newParticleSystem(main.images.spark, 64)
	self.system:setParticleLifetime(0.5, self.max_time)
	self.system:setSpeed(20, 150)
	self.system:setSizes(0.1,0.0125)
	self.system:setSpin(-25,25)
	self.system:setRadialAcceleration(-30,-10)
	self:setColor({255,255,255})
end

function Explosion:setColor(c)
	self.system:setColors(
		c[1], c[2], c[3], 200, 
		c[1], c[2], c[3], 0
	)
	self.color = c
end

function Explosion.on:spawn(e)
	for i=1,64 do
		self.system:setDirection(math.random()*math.pi*2)
		self.system:emit(1)
	end
end

function Explosion.on:update(e,dt)
	self.system:update(dt)
	if self.system:getCount() < 1 then
		e:destroy()
	end
	self.time = self.time + dt
end

function Explosion.on:draw(e)
	love.graphics.draw(self.system, e.x, e.y)

	local c = {unpack(self.color)}
	local t = (self.time/self.max_time)
	c[4] = 48*((1-t)^4)
	love.graphics.setColor(c)
	love.graphics.draw(main.images.ring, e.x, e.y, 0, t*2, t*2, 256, 256)
end

return Explosion
