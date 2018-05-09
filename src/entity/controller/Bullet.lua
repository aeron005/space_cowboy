local Component = require('classes.Component')
local Bullet = Component:extend("Bullet")

local color = require('util.color')

function Bullet:init()
	self.color = {255,255,255}
	self.is_player = false
	self.dir = 0
end

function Bullet.on:update(e,dt)
	if e.x < 0 or e.y < 0
	or e.x > main.display.width
	or e.y > main.display.height then
		e:destroy()
	end
end

function Bullet.on:render(e)
	self.color = color.level(self.level)
	self.trail = self.trails[math.floor(self.level % color.count)]
end

function Bullet.on:draw(e)
	love.graphics.push()
	love.graphics.translate(e.x,e.y)
	love.graphics.rotate(self.dir)

	if self.is_player then
		love.graphics.setColor(255,255,255)
	else
		love.graphics.setColor(self.color)
	end
	love.graphics.polygon("fill",self.v1)
	
	love.graphics.setColor(self.color)
	love.graphics.line(self.v2)
	--love.graphics.draw(self.grad,0,0,0,-100,1)
	love.graphics.draw(self.trail,0,0)
	
	love.graphics.pop()
end

function render(e)
	local s1,s2 = -4,-5
	local d1,d2 = math.pi/8, -math.pi/8
	Bullet.v1 = {
		s1*math.cos(d1),
		s1*math.sin(d1),
		0, 0,
		s1*math.cos(d2),
		s1*math.sin(d2)
	}
	Bullet.v2 = {
		s2*math.cos(d1),
		s2*math.sin(d1),
		0, 0,
		s2*math.cos(d2),
		s2*math.sin(d2)
	}
	--Bullet.grad = color.gradient({{255,255,255,255},{0,0,0,0},{255,255,255,0}})
	Bullet.trails = {}
	for i,v in ipairs(color.names) do
		local c = color.level(i-1)
		Bullet.trails[i-1] = love.graphics.newMesh({
			{8,0,0,0,c[1],c[2],c[3],20},
			{0,2,0,0,c[1],c[2],c[3],10},
			{-128,0,0,0,c[1],c[2],c[3],0},
			{0,-2,0,0,c[1],c[2],c[3],10},
		})
	end
end

render()
return Bullet
