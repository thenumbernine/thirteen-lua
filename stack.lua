local class = require 'ext.class'
local table = require 'ext.table'
local Card = require 'card' 
local Stack = class()
function Stack:init(args)
	self.cards = table(args and args.cards or {})
end
function Stack:last(fromLast)	-- fromLast == 1 <=> last card, fromLast == 2 <=> 2nd to last card
	return self.cards[#self.cards+1-(fromLast or 1)]
end
function Stack:__tostring()
	return self.cards:map(tostring):concat' '
end
function Stack:clone()
	local clone = getmetatable(self)()
	clone.cards = table()
	for i=1,#self.cards do
		clone.cards[i] = Card(self.cards[i])
	end
	return clone
end
return Stack
