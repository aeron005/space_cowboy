local Weapon = class("Weapon")
local color = require('util.color')

Weapon.weapons = {
	pistol = {
		display="Pistol",
		rate=14,
		mag=8,
		count=1,
		reload=30,
		spread=0.05,
		bonus=1.8,
		recoil=0.07
	},
	revolver = {
		display="Revolver",
		rate=20,
		mag=6,
		count=1,
		reload=55,
		spread=0.025,
		bonus=2.5,
		recoil=0.15
	},
	smg = {
		display="SMG",
		rate=5,
		mag=14,
		count=1,
		reload=60,
		spread=0.06,
		bonus=1,
		recoil=0.15
	},
	assault = {
		display="Assault Rifle",
		rate=7,
		mag=24,
		count=1,
		reload=80,
		spread=0.025,
		bonus=1.2,
		recoil=0.1
	},
	shotgun = {	
		display="Shotgun",
		rate=30,
		mag=2,
		count=5,
		reload=70,
		spread=0.175,
		bonus=1,
		recoil=0.6
	},
	minigun = {
		display="Minigun",
		rate=6,
		mag=50,
		count=1,
		reload=200,
		spread=0.09,
		bonus=1,
		recoil=0.1
	},
	combat = {
		display="Combat Shotgun",
		rate=20,
		mag=6,
		count=6,
		reload=160,
		spread=0.1,
		bonus=1.2,
		recoil=0.4
	},
	sniper = {
		display="Sniper",
		rate=40,
		mag=1,
		count=1,
		reload=80,
		spread=0.03,
		bonus=4.5,
		recoil=0.3
	}
}


function Weapon:init(name, level)
	local w = Weapon.weapons[name]
	if not w then w = Weapon.weapons.pistol end
	for k,v in pairs(w) do
		self[k] = v
	end
	self.name = name
	self.level = level
	self.color = color.level(self.level)
	self.ammo = self.mag
end

return Weapon
