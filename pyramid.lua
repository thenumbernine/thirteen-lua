local class = require 'ext.class'
local table = require 'ext.table'
local range = require 'ext.range'
local Stack = require 'cards.stack'
local Pyramid = class()
function Pyramid:init(args)
	if Pyramid:isa(args) then
		self.stacks = table()
		for i,row in ipairs(args.stacks) do
			self.stacks[i] = table()
			for j,stack in ipairs(row) do
				self.stacks[i][j] = stack:clone()
			end
		end
	else
		local deck = args.deck
		self.stacks = range(7):map(function(i)
			return range(i):map(function(j)
				return Stack{cards={deck:takeTop()}}
			end)
		end)
	end
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
function Pyramid.__concat(a,b) return tostring(a) .. tostring(b) end
return Pyramid
