local Stack = require('classes.Stack')
local State = class("State")

function State:init()
	self.state = Stack:new()
end

local function buildEvent(name)
	local capname = name:sub(1,1):upper() .. name:sub(2) 
	local handlename = "on" .. capname
	local postname = "post" .. capname
	State[handlename] = function (parent,...)
		local child = parent.state:peek()
		if(parent[name]) then parent[name](parent,...) end
		if(child) then child[handlename](child,...) end
		if(parent[postname]) then parent[postname](parent,...) end
	end
end

for _,event in ipairs(require('events')) do
	buildEvent(event)
end

return State
