
local Component = require('classes.Component')
local Player = Component:extend("Player")

function Player.on:create(e)
	self.sprite = e.components.sprite
end

function Player.on:action(e,event)
	local tx, ty = 0, 0
	if event == "up" or event == "upleft" or event == "upright" then
		ty = -1
	end

	if event == "down" or event == "downleft" or event == "downright" then
		ty = 1
	end

	if event == "left" or event == "upleft" or event == "downleft" then
		tx = -1
	end

	if event == "right" or event == "upright" or event == "downright" then
		tx = 1
	end

	--e.x = e.x + tx
	--e.y = e.y + ty
	e:broadcast("move",tx,ty)

	--e:broadcast("turn")
end

return Player
