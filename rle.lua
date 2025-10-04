--[[
    rle.lua
    Handles all logic for the Run-Length Encoded (RLE) pattern format.
	requires emptyGrid() from utils

    Contains:
    - save:       Encodes the current grid pattern to the clipboard
    - load:       Loads an RLE pattern from a string onto the grid
    - parseRLE:   Parses a raw RLE string into a pattern table
    - rle_encode: RLE compression algorithm
    - rle_decode: RLE decompression algorithm
]]

local utils = require('utils')


-- @data:  Square table contianing 0/1
-- RL-encodes pattern data and saves it in clipboard
-- https://conwaylife.com/wiki/Run_Length_Encoded
function save(data)

	local text = ''
	local size = #data

	for j = 1, size do
		local line = ''
		for i = 1, size do
			line = line..((data[i][j] == 0) and 'b' or 'o')
		end
		line = rle_encode(line)
		text = text..line..'$'  -- Tag representing end of line
	end
	love.system.setClipboardText( text )
end


-- @size : Integer, size of grid on which pattern will be placed
-- @pattern: String containing pattern
-- returns data table if successful or nil if not
function load(size, pattern)

	-- Remove whitespace, newline
	pattern = pattern:gsub('\n', '')
	pattern = pattern:gsub('%s', '')

	-- Check if decoded text has only valid chars
	if string.match(pattern, '[^ob0-9$!]+') then 
		return nil
	end

	-- Decode pattern, and limit it's size to grid dimensions
	local patternTable, patternHeight, patternWidth = parseRLE(pattern, size)	

	-- Find coords to place pattern in center of grid
	local startX = size/2 - math.floor(patternWidth/2)
	local startY = size/2 - math.floor(patternHeight/2)

	local data = utils.emptyGrid(size)

	for i = 1, #patternTable do
		for j = 1, #patternTable[i] do
			local dx = startY + i
			local dy = startX + j
			data[dy][dx] = (patternTable[i]:sub(j,j)) == 'o' and 1 or 0
		end
	end
	return data
end


-- @text : RLE string
-- Returns a table, patternHeight and patternWidth
function parseRLE(text, size)

	-- Explicitly add 1 before instances of single letters
	-- 2bo -> bobo, 2b1o -> bbo

	text = text:gsub('([ob])([ob])','%11%2')
	text = text:gsub('^([ob])','1%1')
	text = text:gsub('$([ob])','$1%1')

	-- Add ! to end of string if not there
	text = text:gsub('([ob])$','%1!')

	-- Decode patterns like 2$ so that new pattern lines are handled correctly
	text = text:gsub('[%d]+%$',rle_decode)	

	-- Loop through every character, decode and store pattern lines
	local lines = {}
	local line = ''
	local patternWidth = 0

	for char in text:gmatch"." do

		-- Handling end of pattern line
		if (char == "$" or char == "!") then

			-- run-length-decode line
			line = rle_decode(line)

			-- Limit pattern line to size
			line = line:sub(1,size)

			-- Update pattern max width
			patternWidth = math.max(patternWidth, #line)

			-- Insert line into list of lines
			table.insert(lines, line)

			-- Reset line
			line = ''

			-- Stop loop if pattern has ended or 
			-- height of pattern is same as grid height oo$obo
			if #lines == size or char == "!" then
				break
			end

		else   -- If char is not end of line, simply add to line buffer
			line = line..char
		end
	end -- End of looping through every character

	local patternHeight = #lines
	return lines, patternHeight, patternWidth
end



-- https://github.com/kennyledet/Algorithm-Implementations/blob/master/Run_Length_Encoding/Lua/Yonaba/rle.lua
-- Run-Length Encoding Compression algorithm  implementation

-- Compresses an input string using RLE algorithm
-- @str    :  an input string to be compressed
-- returns : the encoded string
function rle_encode(str)
  local prev = str:sub(1,1)
  local count = 0
  local encoded = ''
  for char in str:gmatch('.') do
    if char == prev then
      count = count + 1
    else
      encoded = encoded .. (count .. prev)
      prev = char
      count = 1
    end
  end
  return encoded .. (count .. prev)
end


-- Decodes a given input
-- @str    : an encoded string
-- returns : the original string
function rle_decode(str)
  local decoded_str = ''
  for count, match in str:gmatch('(%d+)([^%d]+)') do
    decoded_str = decoded_str .. (match:rep(count))
  end
  return decoded_str
end



return {
    save = save,
    load = load,
    parseRLE = parseRLE,
    rle_encode = rle_encode,
    rle_decode = rle_decode
}