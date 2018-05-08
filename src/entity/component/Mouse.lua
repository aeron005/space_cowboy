local Component = require('classes.Component')
local Mouse = Component:extend("Mouse",{persist = {"bindings"}})

function Mouse:init(bindings)
	self.bindings = bindings or {}
end

function Mouse.on:create(e)
	e.input = e.input or {}
	for control,name in pairs(self.bindings) do
		e.input[name] = false
	end
end

function Mouse.on:mousepressed(e,button)
	for control,name in pairs(self.bindings) do
		if button == control then
			e.input[name] = true
			e:broadcast("action",name)
		end
	end
end

function Mouse.on:mousereleased(e,button)
	for control,name in pairs(self.bindings) do
		if button == control then
			e.input[name] = false
		end
	end
end

return Mouse
