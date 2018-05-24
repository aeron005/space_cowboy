local random = {}

function random.chance(chance)
	return (math.random()<chance)
end

function random.range(min, max, pow)
	if pow then
		return min+(math.random()^pow)*(max-min)
	else
		return min+math.random()*(max-min)
	end
end

function random.choice(table,pow)
	local n = #table
	if pow then
		return table[math.floor(1+n*(math.random()^pow))]
	end
	return table[math.floor(1+n*math.random())]
end

return random
