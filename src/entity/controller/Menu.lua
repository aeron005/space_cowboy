local Component = require('classes.Component')
local Menu = Component:extend("Menu")


function Menu.on:action(e, action)
	if action == "screenshot" then
		local screenshot = love.graphics.newScreenshot();
		screenshot:encode(os.time() .. '.png','png');
	end
	if action == "new_game" then
		local GameState = require('states.GameState')
		local gs = GameState:new()
		main.state:pop()
		main.state:push(gs)
	end
end

return Menu
