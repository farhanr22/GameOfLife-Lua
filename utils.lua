--[[
    utils.lua
    General-purpose utility functions for data manipulation and logic.

    Contains:
    - emptyGrid:      Creates a new, empty 2D grid table.
    - deepCopy:       Performs a deep copy of a 2D grid table.
    - getRuleTable:   Parses a "B/S" rulestring into a rule table.
    - center:         Centers a string by adding padding.
    - nextListValue:  Cycles to the next value in a list (for speeds, grid sizes).
]]

-- Returns empty grid of given size
function emptyGrid(size)
	local data = {}
	for i = 1, size do
		data[i] = {}
		for j = 1, size do
			data[i][j] = 0
		end
	end
	return data
end


-- Returns a deep copy of a square table
function deepCopy(data)
	local size = #data
	local copy = emptyGrid(size)
	for i = 1, size do
		for j = 1, size do
			copy[i][j] = data[i][j]
		end
	end
	return copy
end


-- @rulestr: String containing ruleString
-- Returns table with B/S values and generated ruleString if input is valid
-- else returns nil
function getRuleTable(rulestr)

    rulestr = rulestr:gsub('\n', '')
    rulestr = rulestr:gsub('%s', '')

    local _, _, b,s = rulestr:find("^B([0-8]+)/S([0-8]*)$")
    if not b and not s then
        return nil
    end

    local ruleTable={["B"]={},["S"]={}}

    for ch in b:gmatch"." do
        ruleTable["B"][tonumber(ch)]=true
    end
    for ch in s:gmatch"." do
        ruleTable["S"][tonumber(ch)]=true
    end

	-- Build up ruleString
	local bNums = 'B'
	local sNums = 'S'
	for var = 0, 8 do
		bNums= bNums .. (ruleTable['B'][var] and var or '')
		sNums= sNums .. (ruleTable['S'][var] and var or '')
	end

	local ruleString = bNums .. '/' .. sNums
    return ruleTable, ruleString

end


-- @text: Text to be centered
-- @width: Width of text area
-- Takes in a string and adds spaces to the left of it
-- to center it in an area of specified width
function center(str, width)
	local half = math.floor(#str/2)
	return string.rep(' ', width/2 - half)..str
end

-- @list: Table containing unique values in increasing order
-- @value: Current value in the table
-- Returns the value in the table after the value passed in
function nextListValue(list, value)

	-- Find what the index of the current value is
	local index = 0
	for i = 1, #list do
		index = (value == list[i]) and i or index
	end

	-- Return the next value or wrap around
	index = (index == #list) and 1 or index + 1
	value = list[index]

	return value
end


return {
    emptyGrid = emptyGrid,
    deepCopy = deepCopy,
    getRuleTable = getRuleTable,
    center = center,
    nextListValue = nextListValue
}