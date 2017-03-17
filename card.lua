local class = require 'ext.class'
local table = require 'ext.table'
local Card = class()
Card.names = table{'A','2','3','4','5','6','7','8','9','T','J','Q','K'}
Card.suits = table{
	{name='spades', symbol='♠'},
	{name='hearts', symbol='♥'},
	{name='diamonds', symbol='♦'},
	{name='clubs', symbol='♣'},
}
Card.facedown = '##'	--facedown-card string.  I might make 'facedown' flag...
function Card:init(args)
	self.value = args.value	-- 1-13
	self.suit = args.suit	-- 1-4
end
function Card:__tostring()
	return self.names[self.value]..self.suits[self.suit].symbol
end
return Card
