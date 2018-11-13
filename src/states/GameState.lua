local State = require('classes.State')
local GameState = State:extend("GameState")

local new = require('entity').create
local Weapon = require('classes.Weapon')
local Sound = require('classes.Sound')
local color = require('util.color')
local random = require('util.random')

function GameState:init()
	GameState.super.init(self)
	self.entities, self.entities_added, self.entities_removed = {}, {}, {}
	self.enemies = 0
	
	local mt,mb,ml,mr = 8,32,8,8
	self.bounds = {
		x=mt,
		y=ml,
		w=main.display.width-(ml+mr),
		h=main.display.height-(mt+mb)
	}

	self.menu = self:create("Menu")
	self.player = self:create("Player", {x=main.display.width/2, y=self.bounds.y+self.bounds.h/2, level=1})
	self:wave(true)
	Sound.vox("welcome")
end

function GameState:wave(guaranteed)
	Sound.play("round")
	local baselevel = self.player.Person.level or self.player.level
	local lvl,x,y

	if random.chance(1/666) then
		for i=1,10 do
			lvl = baselevel+math.random()
			self:create("Enemy", {x=128+i*64, y=128, level=lvl, mod="midget"})
		end
		for i=1,10 do
			lvl = baselevel+math.random()
			self:create("Enemy", {x=128+i*64, y=320, level=lvl, mod="midget"})
		end
		Sound.vox({"rare1","rare2","rare3","rare4","rare5"},2)

	elseif random.chance(1/400) then
		local cx, cy, cr = main.display.width/2, main.display.height/2, main.display.height*3/8
		for i=0,9 do
			if random.chance(3/4) then
				local dir=(i/10)*math.pi*2
				x,y = cx+cr*math.cos(dir), cy+cr*math.sin(dir)
				lvl = baselevel+math.random()
				self:create("Enemy", {x=x, y=y, level=lvl})
			end
		end
		Sound.vox({"rare1","rare2","rare3","rare4","rare5"},2)

	elseif random.chance(1/8) then
		lvl = baselevel+1+(math.random()^2)*2
		x,y = self:randomPosition(32)
		self:create("Enemy", {x=x,y=y,level=lvl,mod="badass"})
		Sound.vox({"threat1","threat2","threat3","threat4","threat5"},4)

	else
		for i=0,9 do
			if random.chance(1/8) or (i<2 and guaranteed) then
				lvl = math.max(0,baselevel+math.random()-2*(math.random()^3))
				x,y = self:randomPosition(16)
				local proto = {x=x,y=y,level=lvl}
				if random.chance(1/8) then
					proto.mod = random.choice({"loot_hungry","fast","trigger_happy","midget"},2)
				end
				self:create("Enemy", proto)
			end
		end
	end
	
	if random.chance(1/4) then
		lvl = baselevel+(math.random()^2)*2
		x,y = self:randomPosition(32)
		local p = self:create("Pickup", {x=x, y=y}).Pickup
		p.weapon = Weapon:new(Weapon.random(), lvl)
		p.level = lvl
	end

	for i=1,3 do
		if random.chance(1/16) then
			lvl = baselevel+math.random()*2
			x,y = self:randomPosition(32)
			local p = self:create("Pickup", {x=x, y=y}).Pickup
			p.level = lvl
		end
	end

end

function GameState:update(dt)
	for e,_ in pairs(self.entities_added) do
		e:broadcast("spawn")
		self.entities[e] = true
		if e.Person and not e.Person.is_player then
			self.enemies = self.enemies + 1
		end
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
		if e.Person and not e.Person.is_player then
			self.enemies = self.enemies - 1
			if self.enemies < 1 then
				Sound.vox({"clear1","clear2","clear3","clear4","clear5"},3)
				self.player.Person:addLevel(0.125)
			end
		end
	end
	self.entities_removed = {}

	if (self.enemies < 4 and random.chance(dt/8))
	or (self.enemies < 1 and random.chance(dt*2))
	then
		self:wave(true)
	elseif random.chance(dt/16) then
		self:wave()
	end

	love.audio.setPosition(self.player.x, self.player.y, 40)
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
	local cx = (main.display.width-(20*(#person.weapons+2)))/2
	for k,v in pairs(person.weapons) do
		local x,y = cx + (k+0.5)*20, self.bounds.h + self.bounds.y*3
		local c = {unpack(color.level(v.level))}
		if not person.best_weapons[k] then
			c[4] = 100
		end
		if person.trash_weapons[k] then
			c[4] = 20
		end
		love.graphics.setColor(c)
		love.graphics.circle("line", x, y, 6, 16)
		if not person.trash_weapons[k] then
			c[4] = 255
			love.graphics.setColor(c)
		end
		if k == person.equipped then
			love.graphics.circle("fill", x, y, 3, 16)
			love.graphics.setColor(255,255,255)
			love.graphics.line(x-4,y+12, x, y+10,  x+4,y+12)
		end
	end

	-- Boundary
	love.graphics.setColor(color.level(person.level))
	love.graphics.rectangle("line",self.bounds.x,self.bounds.y,self.bounds.w,self.bounds.h)

	-- Ammo bar
	local bar_size = 256
	bar_size = self.bounds.w/5

	love.graphics.setColor(255,255,255)
	love.graphics.rectangle("line",self.bounds.x,self.bounds.h + self.bounds.y*3-5,bar_size,10)
	local w = person.weapon
	local aw = (bar_size-4) * (w.ammo / w.mag)
	if person.reloading then
		aw = (bar_size-4) * (1-(person.rt / (w.reload/60)))
	end
	love.graphics.setColor(color.level(person.weapon.level))
	love.graphics.rectangle("fill",self.bounds.x+2,self.bounds.h + self.bounds.y*3-3,aw,6)

	-- Health bar
	love.graphics.setColor(255,255,255)
	love.graphics.rectangle("line",self.bounds.x+self.bounds.w-bar_size,self.bounds.h + self.bounds.y*3-5,bar_size,10)
	local hw = (bar_size-4) * (person.health / person.max_health)
	if hw > 0 then
		love.graphics.setColor(color.level(person.level))
		love.graphics.rectangle("fill",self.bounds.x+self.bounds.w-bar_size+2,self.bounds.h + self.bounds.y*3-3,hw,6)
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
	love.graphics.printf(self.player.Person.weapon.fullname,bar_size+8,10,bar_size,"left")
	love.graphics.setColor(color.level(person.level))
	love.graphics.printf(self.player.Person.class_text,self.bounds.w-bar_size*2-8,10,bar_size,"right")
	love.graphics.pop()
end

function GameState:spawn(e)
	self.entities_added[e] = true
end

function GameState:create(obj,properties)
	local e = new(obj,self)
	if properties then
		for k,v in pairs(properties) do
			e[k] = v
		end
	end
	self:spawn(e)
	return e
end

function GameState:bestEntity(score_func)
	local best, best_score = nil, -math.huge
	for e,_ in pairs(self.entities) do
		local test = score_func(e)
		if not test == false and test > best_score then
			best_score = test
			best = e
		end
	end
	return best
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

local function handleEvent(name)
	GameState[name] = function(self,...)
		if self.player and self.player.active then
			self.player:broadcast(name,...)
		end
		if self.menu then
			self.menu:broadcast(name,...)
		end
	end
end

local events = {
	"keypressed",
	"keyreleased",
	"mousepressed",
	"mousereleased",
	"mousemoved",
	"gamepadpressed",
	"gamepadreleased",
	"gamepadaxis",
	"joystickpressed",
	"joystickreleased",
	"joystickaxis",
	"joystickhat"
}
for _,event in ipairs(events) do
	handleEvent(event)
end

return GameState
