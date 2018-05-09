local Component = require('classes.Component')
local Explosion = Component:extend("Explosion")

local color = require('util.color')

function Explosion:init()
	self.system = love.graphics.newParticleSystem(main.images.spark, 64)
	self.system:setParticleLifetime(0.5, 2)
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
end

function Explosion.on:draw(e)
	love.graphics.draw(self.system, e.x, e.y)
end

return Explosion
