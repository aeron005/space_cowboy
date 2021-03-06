local Component = require('classes.Component')
local Explosion = Component:extend("Explosion")

local color = require('util.color')

function Explosion:init()
	self.time = 0
	self.max_time = 2
	self.size = 64
	self.is_player = false

	self.system = love.graphics.newParticleSystem(main.images.spark, 128)
	self.system:setParticleLifetime(0.5, self.max_time)
	self.system:setSpeed(20, 150)
	self.system:setSizes(0.1,0.0125)
	self.system:setSpin(-25,25)
	self.system:setRadialAcceleration(-30,-10)
	self:setColor({255,255,255})
end

function Explosion:setColor(c,c2)
	self.system:setParticleLifetime(0.5, self.max_time)
	self.system:setColors(
		c[1], c[2], c[3], 200, 
		c[1], c[2], c[3], 0
	)
	self.color = c
	self.color2 = c2 or c
end

function Explosion.on:spawn(e)
	for i=1,self.size do
		self.system:setDirection(math.random()*math.pi*2)
		self.system:emit(1)
	end
end

function Explosion.on:update(e,dt)
	self.system:update(dt)
	if self.time > self.max_time then
		e:destroy()
	end
	self.time = self.time + dt
end

function Explosion.on:draw(e)
	love.graphics.draw(self.system, e.x, e.y)

	local c
	local t = (self.time/self.max_time)
	if self.is_player then
		c = {unpack(self.color)}
	else
		c = {unpack(self.color2)}
	end
	c[4] = 48*((1-t)^4)
	love.graphics.setColor(c)
	love.graphics.draw(main.images.ring, e.x, e.y, 0, t*2, t*2, 256, 256)

	c = {unpack(self.color2)}
	c[4] = 48*((1-t)^4)
	for i=0,9 do
		local d,p = (i/10)*math.pi*2, 512
		local x,y = p*t*math.cos(d), p*t*math.sin(d)
		love.graphics.draw(main.images.spark, e.x+x, e.y+y, d, 1, 1, 128, 128)
		love.graphics.draw(main.images.spark, e.x+x*2, e.y+y*2, d+math.pi/2, 0.25, 1, 128, 128)
	end

	if self.is_player then
		c[4] = 96*((1-t)^4)
		love.graphics.setColor(c)
		love.graphics.draw(main.images.ring, e.x, e.y, 0, t*4, t*4, 256, 256)
	end

end

return Explosion
