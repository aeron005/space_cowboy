local Weapon = class("Weapon")
local color = require('util.color')

Weapon.weapons = {
	pistol = {
		display="Pistol",
		sound="pistol",
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
		sound="revolver",
		rate=18,
		mag=6,
		count=1,
		reload=55,
		spread=0.025,
		bonus=2.75,
		recoil=0.15
	},
	smg = {
		display="SMG",
		sound="smg",
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
		sound="assault",
		rate=8,
		mag=24,
		count=1,
		reload=80,
		spread=0.025,
		bonus=1.2,
		recoil=0.1
	},
	shotgun = {	
		display="Shotgun",
		sound="shotgun",
		rate=30,
		mag=2,
		count=6,
		reload=70,
		spread=0.175,
		bonus=1.1,
		recoil=0.6
	},
	minigun = {
		display="Minigun",
		sound="minigun",
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
		sound="shotgun2",
		rate=25,
		mag=6,
		count=4,
		reload=140,
		spread=0.125,
		bonus=1.2,
		recoil=0.3
	},
	triple = {
		display="Tripleshot",
		sound="tripleshot",
		rate=25,
		mag=4,
		count=3,
		reload=95,
		spread=0.06,
		bonus=1.7,
		recoil=0.25
	},
	double = {
		display="Doubletap",
		sound="double",
		rate=25,
		mag=4,
		count=2,
		reload=50,
		spread=0.05,
		bonus=2.0,
		recoil=0.35
	},
	sniper = {
		display="Sniper",
		sound="sniper",
		rate=40,
		mag=1,
		count=1,
		reload=40,
		spread=0.03,
		bonus=4.0,
		recoil=0.3
	}
}

function Weapon:init(name, level)
	local w = Weapon.weapons[name]
	self.name = name
	if not w then
		w = Weapon.weapons.pistol
		self.name = "pistol"
	end
	for k,v in pairs(w) do
		self[k] = v
	end
	self.level = level
	self.color = color.level(self.level)
	self.ammo = self.mag
	self.fullname = "L"..math.floor(self.level).." "..(color.name(self.level)).." "..self.display
end

Weapon.names = {}
for id,_ in pairs(Weapon.weapons) do
	table.insert(Weapon.names, id)
end
function Weapon.random()
	return Weapon.names[math.random(#Weapon.names)]
end

function Weapon.debug()
	for id,w in pairs(Weapon.weapons) do
		local time = w.rate*w.mag + w.reload
		if w.mag == 1 then time = w.reload end
		local damage = w.count * w.bonus * w.mag
		local dps = math.floor(damage/time*1000)/1000

		--print("="..id.."=")
		--print("time:"..time.."\tdamage:"..damage.."\tdps:"..dps)
		print(id..":\t"..dps)
	end
end
--Weapon.debug()

return Weapon
