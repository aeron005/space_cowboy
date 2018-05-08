local Component = require('classes.Component')
local Keyboard = Component:extend("Keyboard",{persist = {"bindings"}})

function Keyboard:init(bindings)
	self.bindings = bindings or {}
	if bindings.space then
		self.bindings[" "] = bindings.space
	end
end

function Keyboard.on:create(e)
	e.input = e.input or {}
	for control,name in pairs(self.bindings) do
		e.input[name] = false
	end
end

function Keyboard.on:keypressed(e,key)
	for control,name in pairs(self.bindings) do
		if key == control then
			e.input[name] = true
			e:broadcast("action",name)
		end
	end
end

function Keyboard.on:keyreleased(e,key)
	for control,name in pairs(self.bindings) do
		if key == control then
			e.input[name] = false
		end
	end
end

return Keyboard
