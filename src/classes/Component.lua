local Component = class("Component", {active=true,on={},persist={}})

function Component:save()
	local persist = self.persist
	local obj = {}
	for i,var in pairs(persist) do
		obj[var] = self[var]
	end
	return obj
end

function Component:load(obj)
	for i,var in pairs(self.persist) do
		self[var] = obj[var]
	end
end

return Component
