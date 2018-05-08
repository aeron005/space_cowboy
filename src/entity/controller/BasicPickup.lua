local Component = require('classes.Component')
local BasicPickup = Component:extend("BasicPickup")

function BasicPickup:init(type)
	self.type = type
end

function BasicPickup.on:pickup(e,caller)
	caller:pickup(self.type)
end

return BasicPickup
