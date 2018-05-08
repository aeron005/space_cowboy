local classes = {
	Player = {
		Physical=true,
		Person={true},
		Keyboard={
			{w="up",s="down",a="left",d="right",space="shoot"}
		},
		Mouse={
			{l="shoot", wu="inv_prev", wd="inv_next"}
		}
	},

	Enemy = {
		Physical=true,
		Person={false}
	},

	Bullet = {
		Physical={radius=3},
		Bullet=true
	},

	Pickup = {
		Physical=true,
		Pickup=true
	}
}

--
-- No need to edit below this line.
--

local Entity = require('classes.Entity')

function create(class, gs)
	local components = classes[class] or {}
	components.Game = {gs}
	return Entity:new(components)
end

return {create=create}
