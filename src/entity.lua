local classes = {
	Player = {
		Physical={{bounded=true}},
		Person={true},
		Keyboard={
			{w="up",s="down",a="left",d="right",space="shoot",r="reload",q="inv_prev",e="inv_next",lshift="aim"}
		},
		Mouse={
			{l="shoot", r="aim", wu="inv_prev", wd="inv_next"}
		}
	},

	Enemy = {
		Physical={{bounded=true}},
		Person={false}
	},

	Bullet = {
		Physical={{radius=3}},
		Bullet=true
	},

	Pickup = {
		Physical={{friction=0.9,radius=3,bounded=true}},
		Pickup=true
	},
	
	Explosion = {
		Explosion=true
	},

	Menu = {
		Menu=true,
		Keyboard={
			{n="new_game",f9="screenshot"}
		}
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
