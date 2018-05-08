local State = require('classes.State')
local GameState = State:extend("GameState")

local new = require('entity').create
local Weapon = require('classes.Weapon')
local color = require('util.color')

function GameState:init()
	GameState.super.init(self)
	self.entities, self.entities_added, self.entities_removed = {}, {}, {}
	
	self.player = self:create("Player", {x=128, y=128})
	self:create("Enemy", {x=256, y=128, level=12})--.Person:setLevel(2)
	self:create("Enemy", {x=256, y=256, level=4})
	self:create("Enemy", {x=290, y=256, level=6})

	local p = self:create("Pickup", {x=128, y=256}).Pickup
	p.level = 3; p.weapon = Weapon:new('shotgun', p.level)

	p = self:create("Pickup", {x=384, y=128}).Pickup
	p.level = 2; p.weapon = Weapon:new('combat', p.level)

	local mt,mb,ml,mr = 8,32,8,8
	self.bounds = {
		x=mt,
		y=ml,
		w=main.display.width-(ml+mr),
		h=main.display.height-(mt+mb)
	}

end

function GameState:update(dt)
	for e,_ in pairs(self.entities_added) do
		self.entities[e] = true
	end
	self.entities_added = {}

	for e,_ in pairs(self.entities) do
		for c,_ in pairs(self.entities) do
			if e.active and c.active and e:collides(c) then
				e:broadcast("collide", c)
			end
		end

		e:broadcast("update", dt)
		if not e.active then self.entities_removed[e] = true end
	end

	for e,_ in pairs(self.entities_removed) do
		self.entities[e] = nil
	end
	self.entities_removed = {}
end

function GameState:draw()
	for e,_ in pairs(self.entities) do
		e:broadcast("draw")
	end
end

function GameState:postDraw()
	self.player:broadcast("drawCursor")
	
	--local mt,mb,ml,mr = 8,32,8,8
	--love.graphics.rectangle("line",mt,ml,main.display.width-(ml+mr), main.display.height-(mt+mb))

	local person = self.player.Person
	for k,v in pairs(person.weapons) do
		--print(k)
		--print(v)
		local x,y = self.bounds.x + (k-0.5)*14, self.bounds.h + self.bounds.y*2
		love.graphics.setColor(color.level(v.level))
		love.graphics.circle("line", x, y, 4, 16)
		if k == person.equipped then
			love.graphics.circle("fill", x, y, 2, 16)
		end
	end

	love.graphics.setColor(255,255,255)
	love.graphics.rectangle("line",self.bounds.x,self.bounds.y,self.bounds.w,self.bounds.h)

	love.graphics.rectangle("line",self.bounds.x,self.bounds.h + self.bounds.y*3,128,10)
	love.graphics.rectangle("line",self.bounds.x+self.bounds.w-128,self.bounds.h + self.bounds.y*3,128,10)

	local w = person.weapon
	local aw = 124 * (w.ammo / w.mag)
	if person.reloading then
		aw = 124 * (1-(person.rt / (w.reload/60)))
	end
	love.graphics.rectangle("fill",self.bounds.x+2,self.bounds.h + self.bounds.y*3+2,aw,6)

	--[[
	local c = 0
	for k,v in pairs(self.entities) do c = c + 1 end
	love.graphics.push()
	love.graphics.translate(self.bounds.x,self.bounds.h+(self.bounds.y)*2)
	love.graphics.scale(1)
	love.graphics.setFont(main.font.hud)
	love.graphics.print("Space Cowboy - Entities: "..c,0,0)
	love.graphics.pop()
	--]]
end

function GameState:keypressed(...)
	self.player:broadcast("keypressed",...)
end

function GameState:keyreleased(...)
	self.player:broadcast("keyreleased",...)
end

function GameState:mousepressed(x,y,button)
	self.player:broadcast("mousepressed",button)
end

function GameState:mousereleased(x,y,button)
	self.player:broadcast("mousereleased",button)
end

function GameState:spawn(e)
	self.entities_added[e] = true
	e:broadcast("spawn")
end

function GameState:create(obj,properties)
	local e = new(obj,self)
	for k,v in pairs(properties) do
		e[k] = v
	end
	self:spawn(e)
	return e
end

return GameState
