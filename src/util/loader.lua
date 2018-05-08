
-- A softer package loader. Does not throw errors on failure.

local sep = package.config:sub(1,1)
local cache = {}

function file_exists(name)
	if love then
		return love.filesystem.exists(name)
	else
		local f=io.open(name,"r")
		if f~=nil then io.close(f) return true else return false end
	end
end

function loader(name, paths)
	if not cache[name] then
		for i,v in ipairs(paths) do
			local mod = v .. "." .. name
			local path = mod:gsub("%.",sep) .. ".lua"
			if file_exists(path) then
				if love then
					cache[name] = love.filesystem.load(path)()
				else
					cache[name] = dofile(path)
				end
			end
		end
	end
	return cache[name]
end

return loader
