local Entity = class("Entity")
local loader = require('util.loader')

function Entity:init(components)
	self.x, self.y = 0, 0
	self.input = {}
	self.active = true
	import = components or {}
	for mod,args in pairs(import) do
		self:add_component(mod,args)
	end
	self:broadcast("create")
end

function Entity:add_component(mod,args)
	local component = loader(mod, {"entity.controller","entity.component"})
	if component then
		if type(args) ~= 'table' then
			args = {}
		end
		local c = component:new(unpack(args))
		c.Entity = self
		self[mod] = c
	end
end

function Entity:broadcast(name, ...)
	for k,component in pairs(self) do
		local super = getmetatable(component)
		if type(component) == 'table'
		and component.active
		and super
		and super.on
		and super.on[name] ~= nil then
			super.on[name](component,self,...)
		end
	end
end

function Entity:collides()
	return false
end

function Entity:destroy()
	self:broadcast("destroy")
	self.active = false
end

return Entity
