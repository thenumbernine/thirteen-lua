local class = require 'ext.class'
local table = require 'ext.table'
local tolua = require 'ext.tolua'
local Deck = require 'deck'
local Stack = require 'stack'
local Pyramid = require 'pyramid'

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
	clone.pyr = Pyramid(self.pyr)
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
return State
