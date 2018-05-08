local Component = require('classes.Component')
local Game = Component:extend("GameObject")

function Game:init(game_state)
	self.game_state = game_state
end

function Game.on:create(e)
	e.game = self.game_state
	self.active = false
end

return Game
