
local Component = require('classes.Component')
local Menu = Component:extend("Menu")


function Menu.on:action(e, action)
	if action == "screenshot" then
		local screenshot = love.graphics.newScreenshot();
		screenshot:encode(os.time() .. '.png','png');
	end
end

return Menu
