local Stack = class("Stack")

function Stack:init()
	self._children = {}
end

function Stack:push(s)
	table.insert(self._children, s)
end

function Stack:pop()
	return table.remove(self._children)
end

function Stack:peek()
	return self._children[#self._children]
end

return Stack
