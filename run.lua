#!/usr/bin/env luajit
local table = require 'ext.table'
local State = require 'state'

math.randomseed(os.time())
local state = State()
print(state)
print'solving...'

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
