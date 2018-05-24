local Component = require('classes.Component')
local Person = Component:extend("Person")

local Weapon = require('classes.Weapon')
local Sound = require('classes.Sound')
local color = require('util.color')
local random = require('util.random')

local level_base = 4/3
local mods = {
	default={
		health_factor=8,
		radius=7,
		speed=75,
		chase_factor=3/4,
		personal_space=64,
		freq_move=2,
		freq_shoot=4,
		freq_unshoot=8,
		freq_swap=2,
		freq_target=2,
		chance_shoot=1/2,
		chance_unshoot=1/8,
		chance_swap=1/4,
		chance_drop=1/5,
		chance_revenge=1/4,
		chance_target_person=1/4,
		chance_target_pickup=1/4,
	},
	badass={
		health_factor=12,
		radius=10,
		speed=50,
		personal_space=128,
		freq_move=1,
		chance_drop=1,
		chance_revenge=1/2,
		chance_target_pickup=0,
	},
	fast={
		radius=6,
		speed=85,
		freq_move=4,
		freq_shoot=8,
		freq_unshoot=16,
		freq_target=8,
	},
	midget={
		health_factor=5,
		radius=4,
		speed=85,
		personal_space=16,
	},
	trigger_happy={
		freq_shoot=8,
		freq_unshoot=1,
		chance_shoot=7/8,
		chance_unshoot=1/2,
	},
	loot_hungry={
		speed=80,
		chase_factor=5/6,
		freq_move=4,
		freq_target=4,
		freq_swap=6,
		chance_drop=7/8,
		chance_revenge=1/8,
		chance_target_person=1/6,
		chance_target_pickup=3/2,
	},
}

function Person:init(is_player)
	self.is_player = is_player
	self.weapons = {}
	for _,k in pairs({"dir","ddir","ammo","recoil","stabil","bt","rt"}) do
		self[k] = 0
	end
	for _,k in pairs({"reloading"}) do
		self[k] = false
	end
	for k,v in pairs(mods.default) do
		self[k] = v
	end
end

function Person.on:spawn(e)
	if e.mod and mods[e.mod] then
		self[e.mod] = true
		if type(mods[e.mod]) == 'table' then
			for k,v in pairs(mods[e.mod]) do
				self[k] = v
			end
		end
	end

	e.radius = self.radius

	if e.level then
		self:setLevel(e.level)
	else
		self:setLevel(0)
	end

	if self.is_player then
		self:pickupWeapon(Weapon:new("pistol",self.level))
	else
		if random.chance(1/4) or self.badass then
			self:pickupWeapon(Weapon:new(Weapon.random("common"),self.level))
		else
			self:pickupWeapon(Weapon:new("pistol",self.level))
		end
		if self.level > 1 or self.badass then
			self:pickupWeapon(Weapon:new(Weapon.random(),self.level))
		end
		self.target = e.game:randomEntity("Person")
	end
	self:equip(1)

	self.health = self.max_health
end

function Person:setLevel(lvl)
	self.level = lvl
	self.max_health = (level_base^math.floor(self.level))*self.health_factor
	self.color = color.level(self.level)
	if self.is_player then
		self.class_text = string.format("L%.1f %s %s", (math.floor(self.level*10)/10), color.name(self.level), color.class(self.level))
		if self.prev_level then
			if math.floor(self.level) > self.prev_level then
				self.Entity.game:wave(true)
				Sound.vox("levelup")
			end
		end
		self.prev_level = math.floor(self.level)
	end
	self.level_text = string.format("L%d",math.floor(self.level))
end

function Person:addLevel(lvl)
	self:setLevel(self.level+lvl)
end

function Person:equip(wi)
	self.equipped = wi
	self.weapon = self.weapons[wi]
	if self.weapon.ammo < 1 then
		self:reload()
	end
end

function Person.on:update(e, dt)
	local i = e.input
	local left, right, up, down = i.left, i.right, i.up, i.down
	e.dx, e.dy = 0, 0

	-- Aiming and AI
	if self.is_player then
		local mx, my = main:mouseX(), main:mouseY()
		self.dir = math.atan2(my-e.y,mx-e.x)
	else
		self:ai(e,dt)
	end

	-- Movement
	if left then
		e.dx = e.dx-self.speed
	end
	if right then
		e.dx = e.dx+self.speed
	end
	if up then
		e.dy = e.dy-self.speed
	end
	if down then
		e.dy = e.dy+self.speed
	end
	
	-- Shooting
	self.bt = self.bt - dt
	if i.shoot 
	and not self.reloading then
		self:shoot(e)
	end

	-- Stability
	if left or right or up or down then
		self.recoil = self.recoil - self.recoil*dt*2
		self.stabil = self.stabil - self.stabil*dt*4
	else 
		self.recoil = self.recoil - self.recoil*dt*4
		self.stabil = self.stabil - self.stabil*dt*6
	end

	-- Reloading
	if self.reloading then
		self.rt = self.rt - dt
		if self.rt <= 0 then
			self.reloading = false
			self.rt = 0
			self.weapon.ammo = self.weapon.mag
		end
	end

	-- Health regeneration
	if self.health < self.max_health then
		self.health = self.health + self.max_health*dt/16
	end
end

function Person:shoot(e)
	if self.bt < 0 then
		local w = self.weapon
		
		for i=1,w.count do
			local vel = (16 + math.random()*w.bonus)*30
			local rr = self.radius + 4
			local dir = self.dir + self.recoil + math.random()*w.spread*2-w.spread
			local sx,sy = rr*math.cos(self.dir), rr*math.sin(self.dir)
			local dx,dy = vel*math.cos(dir), vel*math.sin(dir)
			local b = e.game:create("Bullet",{x=e.x+sx,y=e.y+sy,dx=dx,dy=dy})
			b.Bullet.dir = dir
			b.Bullet.color = color.level(w.level)
			b.Bullet.level = w.level
			b.Bullet.is_player = self.is_player
			b.Bullet.owner = e
			b.Bullet.bonus = w.bonus
			b:broadcast("render")
		end
		w.ammo = w.ammo - 1
		if w.ammo < 1 then
			self:reload()
		end
		self.bt = w.rate/60
		self.recoil = self.recoil + (w.recoil*math.random()*2-w.recoil)
		self.stabil = self.stabil + w.recoil
		if w.sound then
			Sound.play(w.sound,e.x,e.y)
		end
	end
end

function Person:reload()
	self.rt = self.weapon.reload/60
	self.reloading = true
	if self.is_player then
		Sound.play("reload")
	end
end

function Person:ai(e, dt)
	local i = e.input
	local chasing_pickup = (self.target and self.target.active and self.target.Pickup)
	-- Movement
	if random.chance(dt*self.freq_move) then
		if type(self.target) == 'table'
		and self.target ~= e
		and self.target.active then
			local t = self.target
			local d = math.sqrt((e.x-t.x)^2 + (e.y+t.y)^2)
			local factor = (d > self.personal_space or chasing_pickup) and self.chase_factor or 1-self.chase_factor
			i.left = random.chance(t.x<e.x and factor or 1-factor)
			i.right = random.chance(t.x>e.x and factor or 1-factor)
			i.down = random.chance(t.y>e.y and factor or 1-factor)
			i.up = random.chance(t.y<e.y and factor or 1-factor)
		else
			i.left = random.chance(1/2)
			i.right = random.chance(1/2)
			i.down = random.chance(1/2)
			i.up = random.chance(1/2)
		end
		self.ddir = random.range(-2,2)
	end
	-- Actions
	if i.shoot and random.chance(dt*self.freq_unshoot) then
		i.shoot = random.chance(self.chance_unshoot)
	end
	if random.chance(dt*self.freq_shoot) then
		i.shoot = random.chance(self.chance_shoot)
	end
	if random.chance(dt*self.freq_target)
	and not chasing_pickup
	then
		if random.chance(self.chance_target_person) then
			self.target = e.game:randomEntity("Person")
		elseif random.chance(self.chance_target_pickup) then
			self.target = e.game:randomEntity("Pickup")
		end
	end
	if random.chance(dt*self.freq_swap) then
		if random.chance(self.chance_swap) then
			e:broadcast("action", "inv_prev")
		end
		if random.chance(self.chance_swap) then
			e:broadcast("action", "inv_next")
		end
	end
	-- Targeting
	if type(self.target) == 'table'
	and self.target ~= e
	and self.target.active then
		self.dir = (self.dir*4 + math.atan2(self.target.y-e.y,self.target.x-e.x))/5
	else
		self.dir = self.dir + self.ddir*dt 
	end
end

function Person.on:action(e, action)
	if not self.reloading then
		if action == "inv_prev"
		or action == "inv_next"
		then
			local ni = self.equipped
			if action == "inv_prev" then
				ni = ni - 1
			end
			if action == "inv_next" then
				ni = ni + 1
			end
			if ni < 1 then ni = #self.weapons end
			if ni > #self.weapons then ni = 1 end
			self:equip(ni)
			if self.is_player then
				Sound.play("select")
			end
		end
		if action == "reload" then
			if self.weapon.ammo ~= self.weapon.mag then
				self:reload()
			end
		end
	end
end

function Person.on:destroy(e)
	if self.is_player then
		local expl = e.game:create("Explosion", {x=e.x, y=e.y}).Explosion
		expl.is_player = true
		expl.max_time = 3
		expl:setColor({255,255,255}, self.color)

		if (random.chance(1/100) and self.level < 3)
		or (random.chance(1/8) and self.level < 2)
		then
			Sound.vox({"insult1","insult2","insult3","insult4","insult5"},2)
		else
			Sound.vox("gameover")
		end
	else
		local expl = e.game:create("Explosion", {x=e.x, y=e.y}).Explosion
		expl:setColor(self.color, self.basecolor)
	end
	Sound.play("die",e.x,e.y)

	if random.chance(self.chance_drop) then
		local rd, ri = math.random()*math.pi*2, math.random()*160+160
		local dx, dy = ri*math.cos(rd), ri*math.sin(rd)
		local p = e.game:create("Pickup", {x=e.x, y=e.y, dx=dx, dy=dy}).Pickup
		p.weapon = self.weapon
		p.level = self.weapon.level
	end
end

function Person.on:collide(e,oe)
	if oe.Bullet then
		local b = oe.Bullet
		if b.owner ~= e then
			b.owner.Person:addLevel(0.0025)
			self.health = self.health - (level_base^b.level)*b.bonus
			if self.health < 0 then
				b.owner.Person:addLevel(0.05)
				e:destroy()
				if random.chance(1/8)
				and b.owner.Person.is_player then
					Sound.vox({"compliment1","compliment2","compliment3","compliment4","compliment5"},4)
				end
			else
				if not self.is_player
				and random.chance(self.chance_revenge) then
					self.target = b.owner
				end
			end
			if self.is_player then
				Sound.play("hit",e.x,e.y)
			end
			oe:destroy()
		end
	end

	if oe.Pickup then
		self:addLevel(0.005)
		if oe.Pickup.weapon then
			self:pickupWeapon(oe.Pickup.weapon)
		else
			self.health = self.health + (level_base^oe.Pickup.level)*3
			if self.health > self.max_health then
				self.health = self.max_health
			end
		end
		if self.is_player then
			Sound.play("pickup",e.x,e.y)
		end
		oe:destroy()
	end
end

function Person:pickupWeapon(w)
	local match = nil
	w.ammo = w.mag
	for id,inv in pairs(self.weapons) do
		if w.name == inv.name then
			match = id
		end
	end
	if match
	and w.level > self.weapons[match].level
	then
		self.weapons[match] = w
		if self.equipped == match then
			self:equip(match)
			self.reloading = false
		end
		if self.is_player then
			Sound.vox("upgraded")
		end
	elseif not match then
		table.insert(self.weapons, w)
		if self.is_player and #self.weapons > 1 then
			Sound.vox("new")
		end
	end
	if self.is_player then
		local best = 0
		for id,w in pairs(self.weapons) do
			best = math.max(best, math.floor(w.level))
		end
		self.best_weapons = {}
		self.trash_weapons = {}
		for id,w in pairs(self.weapons) do
			if math.floor(w.level) == best then
				self.best_weapons[id] = true
			end
			if best - math.floor(w.level) > 3 then
				self.trash_weapons[id] = true
			end
		end
	end
end

function Person.on:draw(e)
	love.graphics.setColor(self.color)
	if (self.health/self.max_health) < 0.98 then
		local r2 = math.pi*2*(self.health/self.max_health)
		if r2 > 0.07 then
		love.graphics.arc("line", e.x, e.y, self.radius+3, 0, r2, 32)
		end
	else
		love.graphics.circle("line", e.x, e.y, self.radius+3, 32)
	end

	love.graphics.setColor(0,0,0)
	love.graphics.circle("fill", e.x, e.y, self.radius, 32)

	if self.is_player then
		love.graphics.setColor(255,255,255)
	else
		love.graphics.setColor(self.color)
		love.graphics.setFont(main.font.game)
		love.graphics.printf(self.level_text,e.x-128,e.y+self.radius+8,256,"center")
		--if e.mod then
		--	love.graphics.printf(e.mod,e.x-128,e.y-self.radius-20,256,"center")
		--end
	end
	love.graphics.circle("line", e.x, e.y, self.radius, 32)
	love.graphics.setColor(self.weapon.color)
	love.graphics.line(e.x, e.y, e.x+self.radius*math.cos(self.dir), e.y+self.radius*math.sin(self.dir))
end

function Person.on:drawCursor(e)
	local mx, my = main:mouseX(), main:mouseY()
	local rr = math.max(math.sqrt((e.x-mx)*(e.x-mx) + (e.y-my)*(e.y-my)) * math.tan(self.weapon.spread + self.stabil),8)
	local r = math.max( 128*math.tan(self.stabil),8)/2
	local c = {unpack(self.weapon.color)}

	love.graphics.push()
	love.graphics.translate(mx,my)
	love.graphics.rotate(self.dir)

	local sc = 512
	c[4] = math.pow((sc-math.min(math.max(0, rr),sc))/sc,2)*48
	love.graphics.setColor(c)
	love.graphics.circle("fill",0,0,rr,64)

	c[4] = 128
	love.graphics.setColor(c)
	--love.graphics.rectangle("fill",-1,-12-r,2,8)
	--love.graphics.rectangle("fill",-1,r+4,2,8)
	--love.graphics.rectangle("fill",-12-r,-1,8,2)
	--love.graphics.rectangle("fill",r+4,-1,8,2)
	love.graphics.rectangle("fill",-4,-9-r,8,2)
	love.graphics.rectangle("fill",-4,r+7,8,2)
	--love.graphics.rectangle("fill",-16,-1,8,2)
	--love.graphics.rectangle("fill",8,-1,8,2)

	c[4] = 192
	love.graphics.setColor(c)
	--love.graphics.circle("line",0,0,rr,64)
	love.graphics.circle("line",0,0,0.1,8)

	love.graphics.pop()
end

return Person
