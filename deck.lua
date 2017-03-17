local class = require 'ext.class'
local table = require 'ext.table'
local Stack = require 'stack'
local Card = require 'card'
local Deck = class(Stack)
function Deck:init()
	Deck.super.init(self)
	for value=1,13 do
		for suit=1,4 do
			self.cards:insert(Card{value=value, suit=suit})
		end
	end
end
-- in-place, returns self.
-- this invalidates self.cards.  if that matters then i could do it twice to restore the same table...
function Deck:shuffle()
	local cards = table()
	while #self.cards > 0 do
		cards:insert(self.cards:remove(math.random(#self.cards)))
	end
	self.cards = cards
	return self
end
function Deck:takeTop()
	return self.cards:remove()
end
return Deck
