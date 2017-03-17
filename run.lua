#!/usr/bin/env luajit
require 'ext'

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

local Pyramid = class()
function Pyramid:init(args)
	local deck = args.deck
	self.stacks = range(7):map(function(i)
		return range(i):map(function(j)
			return Stack{cards={deck:takeTop()}}
		end)
	end)
end
function Pyramid:clone()
	local clone = setmetatable({}, Pyramid)
	clone.stacks = table()
	for i,row in ipairs(self.stacks) do
		clone.stacks[i] = table()
		for j,stack in ipairs(row) do
			clone.stacks[i][j] = stack:clone()
		end
	end
	return clone
end
function Pyramid:getOpenPositions()
	local pos = table()	-- table-of-locations in the pyramid of topmost cards
	for i,row in ipairs(self.stacks) do
		for j,stack in ipairs(row) do
			if #stack.cards > 0 then	-- if there is a card there
				if not self.stacks[i+1]	-- if it's the bottom row
				or ((not self.stacks[i+1][j] or #self.stacks[i+1][j].cards == 0)	-- there is no stack below/left or it has no cards ... and ...
					and (not self.stacks[i+1][j+1] or #self.stacks[i+1][j+1].cards == 0))	-- there is no stack below/right or it has no cards ...
				then
					pos:insert{i,j}
				end
			end
		end
	end
	return pos
end
function Pyramid:__tostring()
--	local pos = self:getOpenPositions()
	local s = table()
	for i,row in ipairs(self.stacks) do
		s:insert((' '):rep(#self.stacks-i))
		local sep = ''
		for j,stack in ipairs(row) do
			s:insert(sep)
--			if pos:find(nil, function(ij) return ij[1]==i and ij[2]==j end) then
				s:insert(tostring(stack.cards[1] or '  '))
--			else
--				s:insert(Card.facedown)
--			end
			sep = ' '
		end
		s:insert'\n'
	end
	return s:concat()
end

-- operates in-place
local Move = class()
function Move:init(args)
	if args then for k,v in pairs(args) do self[k] = v end end
end
function Move:__tostring()
	return tolua(table(self, {
		name=self.name,
	}))
end

local MoveFromDeckToDiscard = class(Move)	-- move card from deck to discard
MoveFromDeckToDiscard.name = 'from deck to discard'
function MoveFromDeckToDiscard:__call(state)
	state.discard.cards:insert(state.deck.cards:remove())
end

local MovePlayDiscard = class(Move)			-- remove and count top discard card
MovePlayDiscard.name = 'play discard'
function MovePlayDiscard:__call(state)
	state.discard.cards:remove()
end

local MovePlayDiscard2 = class(Move)		-- remove and count top two discard cards
MovePlayDiscard2.name = 'play top two discards' 
function MovePlayDiscard2:__call(state)
	state.discard.cards:remove()
	state.discard.cards:remove()
end

local MovePlayDiscardAndPyramid = class(Move)
MovePlayDiscardAndPyramid.name = 'play discard and pyramid' 
function MovePlayDiscardAndPyramid:__call(state)
	state.discard.cards:remove()
	local i,j = table.unpack(self.pos)
	state.pyr.stacks[i][j].cards:remove()
end

local MovePlayPyramid = class(Move)
MovePlayPyramid.name = 'play pyramid'
function MovePlayPyramid:__call(state)
	local i,j = table.unpack(self.pos)
	state.pyr.stacks[i][j].cards:remove()
end

local MovePlayPyramid2 = class(Move)
MovePlayPyramid2.name = 'play two pyramid' 
function MovePlayPyramid2:__call(state)
	local i,j = table.unpack(self.pos)
	state.pyr.stacks[i][j].cards:remove()
	local i2,j2 = table.unpack(self.pos2)
	state.pyr.stacks[i2][j2].cards:remove()
end

local State = class()
function State:init(src)
	-- new game
	self.deck = Deck():shuffle()
	self.discard = Stack()
	self.pyr = Pyramid{deck=self.deck}
end
function State:clone()
	local clone = State()
	clone.deck = self.deck:clone()
	clone.discard = self.discard:clone()
	clone.pyr = self.pyr:clone()
	return clone
end
function State:__tostring()
	local s = table()
	s:insert('deck:'..self.deck..'\n')
	s:insert('discard:'..self.discard..'\n')
	s:insert('pyramid:\n'..self.pyr)
	s:insert('open positions: '..self.pyr:getOpenPositions():map(function(ij) return table.concat(ij,',') end):concat' '..'\n')
	return s:concat()
end
function State:won()
	if #self.deck.cards > 0 then return false end
	if #self.discard.cards > 0 then return false end
	for i,row in ipairs(self.pyr.stacks) do
		for j,stack in ipairs(row) do
			if #stack.cards > 0 then return false end
		end
	end
	return true
end
function State:moves()
	local positions = self.pyr:getOpenPositions()
	local moves = table()
	
	-- 3) match one or two cards on the board
	for posindex=1,#positions do
		local pos = positions[posindex]
		local i,j = table.unpack(pos)
		local cardij = self.pyr.stacks[i][j].cards[1]
		if cardij.value == 13 then
			moves:insert((MovePlayPyramid{pos=pos}))
		else
			for posindex2=posindex+1,#positions do
				local pos2 = positions[posindex2]
				local i2,j2 = table.unpack(pos2)
				local cardij2 = self.pyr.stacks[i2][j2].cards[1]
				if cardij.value + cardij2.value == 13 then
					moves:insert((MovePlayPyramid2{pos=pos,pos2=pos2}))
				end
			end
		end
	end
	
	local topDiscard = self.discard:last()
	-- 1) flip a card over to the discard
	if #self.deck.cards > 0 then
		moves:insert((MoveFromDeckToDiscard()))
	end
	-- 2.-2) play a single discard card
	if topDiscard then
		if topDiscard.value == 13 then
			moves:insert((MovePlayDiscard()))
		end
	end
	-- 2.-1) play a discard on itself
	if #self.discard.cards >= 2 then
		if topDiscard.value + self.discard:last(2).value == 13 then
			moves:insert((MovePlayDiscard2()))
		end
	end
	-- 2) play a card on the discard to the board (if a place allows it)
	if topDiscard then
		for _,pos in ipairs(positions) do
			local i,j = table.unpack(pos)
			if topDiscard.value + self.pyr.stacks[i][j].cards[1].value == 13 then
				moves:insert((MovePlayDiscardAndPyramid{pos=pos}))
			end
		end
	end
	
	return moves
end
local state = State()

local numMoves = 0
local lastTime = os.time()
local states = table{state}
while #states > 0 do
	local state = states:remove()	-- pop last = depth first
	--local state = states:remove(1)	-- pop first = breadth first, runs out of memory quickly
	local moves = state:moves()
	local won = state:won()
	if won then
		for _,prevstate in ipairs(states) do
			if prevstate.lastmove then print('last move:',prevstate.lastmove) end
			print(prevstate)
		end
		if state.lastmove then print('last move:',state.lastmove) end
		print(state)
		
		print"you won!" 
		os.exit()
	end
	for _,move in ipairs(moves) do
		local newstate = state:clone()
		move(newstate)
		newstate.lastmove = move
		states:insert(newstate)
	end
	numMoves = numMoves + #moves
	local thisTime = os.time()
	if thisTime ~= lastTime then
		print('total # moves:', numMoves)
		lastTime = thisTime
	end
end
