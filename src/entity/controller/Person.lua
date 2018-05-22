local Component = require('classes.Component')
local Person = Component:extend("Person")

local color = require('util.color')
local Weapon = require('classes.Weapon')
local Sound = require('classes.Sound')

function Person:init(is_player)
	self.is_player = is_player
	self.weapons = {}
	for _,k in pairs({"dir","ddir","ammo","recoil","stabil","bt","rt"}) do
		self[k] = 0
	end
	for _,k in pairs({"reloading"}) do
		self[k] = false
	end
end

function Person.on:spawn(e)
	if e.level then
		self:setLevel(e.level)
	else
		self:setLevel(0)
	end

	if self.is_player then
		self:pickupWeapon(Weapon:new("pistol",self.level+1))
	else
		if math.random() < 0.25 then
			self:pickupWeapon(Weapon:new(Weapon.random("common"),self.level))
		else
			self:pickupWeapon(Weapon:new("pistol",self.level))
		end
		if self.level > 1 then
			self:pickupWeapon(Weapon:new(Weapon.random(),self.level))
		end
		self.target = e.game:randomEntity("Person")
	end
	self:equip(1)

	self.health = self.max_health
end

function Person:setLevel(lvl)
	self.level = lvl
	self.max_health = (1.5^math.floor(self.level))*8
	self.radius = 8
	self.Entity.radius = self.radius
	self.color = color.level(self.level)
	if self.is_player then
		self.class = "L"..(math.floor(self.level*10)/10).." "..color.name(self.level).." "..color.class(self.level)
		if self.prev_level then
			if math.floor(self.level) > self.prev_level then
				Sound.vox("levelup")
			end
		end
		self.prev_level = math.floor(self.level)
	end
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
	local speed = 75
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
		e.dx = e.dx-speed
	end
	if right then
		e.dx = e.dx+speed
	end
	if up then
		e.dy = e.dy-speed
	end
	if down then
		e.dy = e.dy+speed
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
	-- Movement
	if math.random() < dt*2 then
		if type(self.target) == 'table'
		and self.target ~= e
		and self.target.active then
			local t = self.target
			i.left = math.random() < (t.x<e.x and 0.7 or 0.3)
			i.right = math.random() < (t.x>e.x and 0.7 or 0.3)
			i.down = math.random() < (t.y>e.y and 0.7 or 0.3)
			i.up = math.random() < (t.y<e.y and 0.7 or 0.3)
		else
			i.left = math.random() < 0.5
			i.right = math.random() < 0.5
			i.down = math.random() < 0.5
			i.up = math.random() < 0.5
		end
		self.ddir = (math.random() - 0.5) * 4
	end
	-- Actions
	if i.shoot and math.random() < dt*8 then
		i.shoot = math.random() < 0.125
	end
	if math.random() < dt*4 then
		i.shoot = math.random() < 0.5
	end
	if math.random() < dt*2 then
		if math.random() < 0.25 then
			self.target = e.game:randomEntity("Person")
		elseif math.random() < 0.25 then
			self.target = e.game:randomEntity("Pickup")
		end
		if math.random() < 0.25 then
			e:broadcast("action", "inv_prev")
		end
		if math.random() < 0.25 then
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

		if (math.random() < 0.0125 and self.level < 3)
		or (math.random() < 0.125 and self.level < 1)
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

	if math.random() < 0.2 then
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
			self.health = self.health - (1.5^b.level)*b.bonus
			if self.health < 0 then
				b.owner.Person:addLevel(0.025)
				e:destroy()
				if math.random() < 0.125
				and b.owner.Person.is_player then
					Sound.vox({"compliment1","compliment2","compliment3","compliment4","compliment5"},4)
				end
			else
				if not self.is_player
				and math.random() < 0.25 then
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
		self:addLevel(0.0025)
		if oe.Pickup.weapon then
			self:pickupWeapon(oe.Pickup.weapon)
		else
			self.health = self.health + (1.5^oe.Pickup.level)*3
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
