local State = require('classes.State')
local GameState = State:extend("GameState")

local new = require('entity').create
local Weapon = require('classes.Weapon')
local color = require('util.color')

function GameState:init()
	GameState.super.init(self)
	self.entities, self.entities_added, self.entities_removed = {}, {}, {}
	
	local mt,mb,ml,mr = 8,32,8,8
	self.bounds = {
		x=mt,
		y=ml,
		w=main.display.width-(ml+mr),
		h=main.display.height-(mt+mb)
	}

	self.player = self:create("Player", {x=main.display.width/2, y=self.bounds.y+self.bounds.h/2, level=0})
	self:wave(true)
end

function GameState:wave(guaranteed)
	local baselevel = self.player.Person.level or self.player.level
	local lvl,x,y
	if math.random() < 0.0015 then
		for i=1,10 do
			lvl = baselevel+math.random()
			self:create("Enemy", {x=128+i*64, y=128, level=lvl})
		end
		for i=1,10 do
			lvl = baselevel+math.random()
			self:create("Enemy", {x=128+i*64, y=320, level=lvl})
		end
	elseif math.random() < 0.0025 then
		local cx, cy, cr = main.display.width/2, main.display.height/2, main.display.height*3/8
		for i=0,9 do
			if math.random() < 0.5 then
				local dir=(i/10)*math.pi*2
				x,y = cx+cr*math.cos(dir), cy+cr*math.sin(dir)
				lvl = baselevel+math.random()-(baselevel)*math.random()
				self:create("Enemy", {x=x, y=y, level=lvl})
			end
		end
	else
		for i=0,9 do
			if math.random() < 0.125 or (i<2 and guaranteed) then
				lvl = baselevel+math.random()
				x,y = self:randomPosition(16+lvl/4)
				self:create("Enemy", {x=x,y=y,level=lvl})
			end
		end
	end
	
	if math.random() < 0.25 then
		lvl = baselevel+math.random()*2
		x,y = self:randomPosition(32)
		local p = self:create("Pickup", {x=x, y=y}).Pickup
		p.weapon = Weapon:new(Weapon.random(), lvl)
		p.level = lvl
	end

	for i=1,3 do
		if math.random() < 0.125 then
			lvl = baselevel+math.random()*2
			x,y = self:randomPosition(32)
			local p = self:create("Pickup", {x=x, y=y}).Pickup
			p.level = lvl
		end
	end

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
	if math.random() < dt/8 then
		self:wave()
	end
end

function GameState:draw()
	for e,_ in pairs(self.entities) do
		e:broadcast("draw")
	end
end

function GameState:postDraw()
	if self.player.active then
		self.player:broadcast("drawCursor")
	end
	
	-- Inventory
	local person = self.player.Person
	local cx = (main.display.width-(24*(#person.weapons+2)))/2
	for k,v in pairs(person.weapons) do
		local x,y = cx+self.bounds.x + k*24, self.bounds.h + self.bounds.y*3
		love.graphics.setColor(color.level(v.level))
		love.graphics.circle("line", x, y, 6, 16)
		if k == person.equipped then
			love.graphics.circle("fill", x, y, 3, 16)
		end
	end

	-- Boundary
	love.graphics.setColor(color.level(person.level))
	love.graphics.rectangle("line",self.bounds.x,self.bounds.y,self.bounds.w,self.bounds.h)
	love.graphics.setColor(255,255,255)

	-- Ammo bar
	local bar_size = 256
	love.graphics.rectangle("line",self.bounds.x,self.bounds.h + self.bounds.y*3,bar_size,10)
	local w = person.weapon
	local aw = (bar_size-4) * (w.ammo / w.mag)
	if person.reloading then
		aw = (bar_size-4) * (1-(person.rt / (w.reload/60)))
	end
	love.graphics.rectangle("fill",self.bounds.x+2,self.bounds.h + self.bounds.y*3+2,aw,6)

	-- Health bar
	love.graphics.rectangle("line",self.bounds.x+self.bounds.w-bar_size,self.bounds.h + self.bounds.y*3,bar_size,10)
	local hw = (bar_size-4) * (person.health / person.max_health)
	if hw > 0 then
		love.graphics.rectangle("fill",self.bounds.x+self.bounds.w-bar_size+2,self.bounds.h + self.bounds.y*3+2,hw,6)
	end

	--[[
	local c = 0
	for k,v in pairs(self.entities) do c = c + 1 end
	--]]
	love.graphics.push()
	love.graphics.translate(self.bounds.x,self.bounds.h+(self.bounds.y))
	--love.graphics.scale(1)
	--love.graphics.setFont(main.font.hud)
	--love.graphics.print(self.player.Person.weapon.fullname,bar_size+16,0)
	love.graphics.setFont(main.font.game)
	love.graphics.setColor(color.level(person.weapon.level))
	love.graphics.print(self.player.Person.weapon.fullname,0,3)
	love.graphics.setColor(color.level(person.level))
	love.graphics.print(self.player.Person.class,self.bounds.w-bar_size,3)
	love.graphics.pop()
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

function GameState:randomPosition(r)
	r = r or 32
	return self.bounds.x+r+math.random()*(self.bounds.w-r*2), self.bounds.y+r+math.random()*(self.bounds.h-r*2)
end

function GameState:randomEntity(class)
	local t = {}
	for e,_ in pairs(self.entities) do
		if e[class] then
			table.insert(t, e)
		end
	end
	for e,_ in pairs(self.entities_added) do
		if e[class] then
			table.insert(t, e)
		end
	end
	return t[math.random(#t)]
end

return GameState
