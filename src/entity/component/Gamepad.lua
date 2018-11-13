local Component = require('classes.Component')
local Gamepad = Component:extend("Gamepad",{persist = {"bindings"}})

function Gamepad:init(bindings)
	self.bindings = bindings or {}
	if bindings.space then
		self.bindings[" "] = bindings.space
	end
end

function Gamepad.on:create(e)
	e.input = e.input or {}
	for control,name in pairs(self.bindings) do
		e.input[name] = false
	end
end

function Gamepad.on:gamepadpressed(e,joystick,button)
	for control,name in pairs(self.bindings) do
		if button == control then
			e.input[name] = true
			e:broadcast("action",name)
		end
	end
end

function Gamepad.on:gamepadreleased(e,joystick,button)
	for control,name in pairs(self.bindings) do
		if button == control then
			e.input[name] = false
		end
	end
end

function Gamepad.on:gamepadaxis(e,joystick,axis,value)
	local thresh = 0.5
	local state = false
	local me, other = axis, axis

	if value < 0 then
		me = me .. "_neg"
		other = other .. "_pos"
	elseif value > 0 then
		me = me .. "_pos"
		other = other .. "_neg"
	end

	if value > thresh
	or value < -thresh
	then
		state = true
	end
	
	for control,name in pairs(self.bindings) do
		if me == control then
			e.input[name] = state
			if state then
				e:broadcast("action",name)
			end
		end
		
		if other == control then
			e.input[name] = false
		end
	end
end

return Gamepad
