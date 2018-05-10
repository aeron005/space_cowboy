local Sound = {}
Sound.sources = {}

function Sound.update()
	local remove = {}
	for _,s in pairs(Sound.sources) do
		if s:isStopped() then
			table.insert(remove,s)
		end
	end

	for i,s in ipairs(remove) do
		Sound.sources[s] = nil
		if s==Sound.current_vox then
			Sound.current_vox = nil
		end
	end
end

function Sound.play(sfx,x,y)
	local source = love.audio.newSource("data/sfx/"..sfx..".wav", "static")
	if x and y then
		source:setPosition(x,y,0)
		--source:setAttenuationDistances(32,128)
		source:setRolloff(0.00125)
	else
		source:setRelative(true)
	end
	love.audio.play(source)
	Sound.sources[source] = source
end

function Sound.vox(phrase,pow)
	if type(phrase) == "table" then
		pow = pow or 1
		local n = #phrase
		local p = phrase[math.floor(1+n*(math.random()^pow))]
		phrase = p
	end
	local source = love.audio.newSource("data/vox/"..phrase..".wav", "static")
	source:setRelative(true)
	if Sound.current_vox then
		Sound.current_vox:stop()
	end
	love.audio.play(source)
	Sound.sources[source] = source
	Sound.current_vox = source
end

return Sound
