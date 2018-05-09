class = require('util.30log')
inspect = require('util.inspect')
math.randomseed(os.time()) 

local State = require('classes.State')
main = State:new()

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.mouse.setVisible(false)

	main.display = { x = 0, y = 0, width = 960, height = 540 }
	main.font = {
		hud=love.graphics.newFont("data/fonts/hud.ttf",12),
		game=love.graphics.newFont("data/fonts/game.ttf",9)
	}
	main.images = {
		spark=love.graphics.newImage("data/images/spark.png")
	}

	local w,h = love.window.getMode()
	love.resize(w, h)

	local GameState = require('states.GameState')
	local gs = GameState:new()
	main.state:push(gs)
end

function love.resize(sw, sh)
	--main.display.width = w
	--main.display.height = h
	--main.display.scaled_width = w / main.display.scale
	--main.display.scaled_height = h / main.display.scale
	---[[
	local cw, ch = main.display.width, main.display.height
	local cr, sr = ch/cw, sh/sw
	
	if cr < sr then
		main.display.scale = sw / cw
		main.display.x, main.display.y = 0, (sh - ch*main.display.scale)/2
	else
		main.display.scale = sh / ch
		main.display.x, main.display.y = (sw - cw*main.display.scale)/2, 0
	end
	--]]
end

function main:draw()
	--love.graphics.setCanvas(self.canvas)

	love.graphics.translate(self.display.x, self.display.y)
	love.graphics.scale(self.display.scale)
end

function main:postDraw()
	--love.graphics.setCanvas()
	--love.graphics.draw(self.canvas, main.display.x, main.display.y, 0, main.display.scale, main.display.scale)
end

function main:mouseX()
	return math.floor((love.mouse.getX() - self.display.x) / self.display.scale)
end

function main:mouseY()
	return math.floor((love.mouse.getY() - self.display.y) / self.display.scale)
end

local fullscreen = true
function main:keypressed(key)
	if key == "escape" then
		love.event.quit()
	elseif key == "f11" then
		fullscreen = not fullscreen
		love.window.setFullscreen(fullscreen, "desktop")
	end	
end

--- Bind main methods for Love to use directly as callbacks
local function wrap(name)
	return function (...) main[name](main,...) end
end

-- It's like magic!
love.update = wrap("onUpdate")
love.draw = wrap("onDraw")
love.keypressed = wrap("onKeypressed")
love.keyreleased = wrap("onKeyreleased")
love.mousepressed = wrap("onMousepressed")
love.mousereleased = wrap("onMousereleased")
love.focus = wrap("onFocus")

