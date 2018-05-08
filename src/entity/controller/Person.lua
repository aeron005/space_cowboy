local Component = require('classes.Component')
local Person = Component:extend("Person")

local color = require('util.color')
local Weapon = require('classes.Weapon')

function Person:init(is_player)
	self.is_player = is_player
	self.weapons = { Weapon:new("pistol",1), Weapon:new("smg",0) }
	self:equip(1)
	for _,k in pairs({"dir","ammo","recoil","stabil","bt","rt","ct"}) do
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
	self.health = self.max_health
end

function Person:setLevel(lvl)
	self.level = lvl
	self.max_health = (self.level + 1)*6
	self.radius = 8 + self.level/4
	self.Entity.radius = self.radius
	self.color = color.level(self.level)
end

function Person:equip(wi)
	self.equipped =  wi
	self.weapon = self.weapons[wi]
end

function Person.on:update(e, dt)
	local i = e.input
	local left, right, up, down = i.left, i.right, i.up, i.down
	local speed = 100
	
	e.dx, e.dy = 0, 0

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
	if self.is_player then
		local mx, my = main:mouseX(), main:mouseY()
		self.dir = math.atan2(my-e.y,mx-e.x)
	end
	
	self.bt = self.bt - dt
	if i.shoot and not self.reloading then
		if self.bt < 0 then
			local w = self.weapon
			
			for i=1,w.count do
				local vel = (10 + math.random()*w.bonus)*60
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
			if w.ammo == 0 then
				self.rt = w.reload/60
				self.reloading = true
			end
			self.bt = w.rate/60
			self.recoil = self.recoil + (w.recoil*math.random()*2-w.recoil)
			self.stabil = self.stabil + w.recoil
		end
	end

	if left or right or up or down then
		self.recoil = self.recoil - self.recoil*dt*2
		self.stabil = self.stabil - self.stabil*dt*4
	else 
		self.recoil = self.recoil - self.recoil*dt*4
		self.stabil = self.stabil - self.stabil*dt*6
	end

	if self.reloading then
		self.rt = self.rt - dt
		if self.rt <= 0 then
			self.reloading = false
			self.rt = 0
			self.weapon.ammo = self.weapon.mag
		end
	end

	if self.health < self.max_health then
		self.health = self.health + (self.level+1)*dt/3
	end

	self.ct = self.ct + dt % math.pi
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
	c[4] = math.pow((sc-math.min(math.max(0, rr),sc))/sc,2)*24
	love.graphics.setColor(c)
	love.graphics.circle("fill",0,0,rr,64)

	c[4] = 64
	love.graphics.setColor(c)
	--love.graphics.rectangle("fill",-1,-12-r,2,8)
	--love.graphics.rectangle("fill",-1,r+4,2,8)
	--love.graphics.rectangle("fill",-12-r,-1,8,2)
	--love.graphics.rectangle("fill",r+4,-1,8,2)
	love.graphics.rectangle("fill",-4,-9-r,8,2)
	love.graphics.rectangle("fill",-4,r+7,8,2)
	--love.graphics.rectangle("fill",-16,-1,8,2)
	--love.graphics.rectangle("fill",8,-1,8,2)

	c[4] = 128
	love.graphics.setColor(c)
	--love.graphics.circle("line",0,0,rr,64)
	love.graphics.circle("line",0,0,0.1,8)

	love.graphics.pop()
end

function Person.on:collide(e,oe)
	if oe.Pickup then
		if oe.Pickup.weapon then
			table.insert(self.weapons, oe.Pickup.weapon)
			--self:equip(#self.weapons)
		end
		oe:destroy()
	end
end

return Person
