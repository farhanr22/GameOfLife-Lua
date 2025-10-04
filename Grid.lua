--[=[
Class with a basic implemention of Game of Life,
with methods for clearing/randomzing/resizing grid

- Grid data is stored as a 2D table in grid.data (and grid.oldData), iterate using grid:next()
- Don't change grid.size manually, call grid:setGridSize(x) instead
- Custom rules are supported, pass a correctly formed table to init
- requires emptyGrid() and deepCopy() from utils.lua
]=]--

utils = require('utils')

Grid = Class{}

function Grid:init(size, ruleTable, cellData, wrapMode)	
	self.size = size	--Number of cells on each side, only necessary arg

	if not ruleTable then		-- 
		self.ruleTable = {["B"]= {[3]=true} , ["S"]= {[2]=true, [3] = true}}
	else self.ruleTable = ruleTable end			-- Table describing birth/survival behaviour
	
	self.data = cellData and cellData or utils.emptyGrid(size)		--Initial grid contents
	self.oldData = utils.emptyGrid(self.size)			-- Prev grid generation
	
	self.wrap = false or wrapMode		-- Outisde edges dead by default
end


function Grid:clear()
	local temp = utils.emptyGrid(self.size)
	self.data = temp
	self.oldData = temp
end


function Grid:randomize()
	self:clear()
	for i = 1, self.size do
		for j = 1, self.size do	
			self.data[i][j] = math.random(0,1)
		end
	end	
end


-- Calculates next gen based on rules
function Grid:next()
	
	-- Copy current data table into oldData, current data gets updated
	self.oldData = utils.deepCopy(self.data)
	local size = #self.data
	
	-- Iterate through each cell
	for i = 1, size do	
		for j = 1, size do
		
			local live_n = 0
			
			-- Iterate through offset values
			for a = -1, 1 do
				for b = -1, 1 do
				
					if self.wrap then -- Torus mode, wrap around opposite edges
						-- (Adding -1/1 to deal with 1-indexed array)
					    local ix = (i + a + size - 1 ) % size	
					    local jy = (j + b + size - 1) % size
					
					    -- Increment number of live neighbours
					    live_n = live_n + self.oldData[ix + 1][jy + 1]
					else  -- Dead edges mode
					    if not ((i + a == 0) or (i + a == self.size + 1) or (j + b == 0) or (j + b == self.size +1)) then
						    live_n = live_n + self.oldData[i + a][j + b]
					    end
					end
				end						
			end 
			
			-- Subtract value of current cell
			live_n = live_n - self.oldData[i][j]
			
			-- If cell is dead, check for birth conditions
			if self.oldData[i][j] == 0 then
				if self.ruleTable["B"][live_n] then
					self.data[i][j] = 1
				end
			else 
				-- If cell was alive, check survival conditions
				if self.ruleTable["S"][live_n] then
					self.data[i][j] = 1
				else 
					self.data[i][j] = 0
				end				
			end			
		end
	end
end


-- @newSize: Integer, size of grid
function Grid:setGridSize(newSize)
	
	local oldSize = self.size	--remember previous size
	local newIsLarger = newSize > oldSize and true or false	
	local oldGrid = utils.deepCopy(self.data)
	
	self.size = newSize	
	self.data = utils.emptyGrid(self.size)
	self.oldData = utils.emptyGrid(self.size)

	-- If new grid is larger, place existing grid at the center
	if newIsLarger then	
		local offset = (newSize - oldSize) / 2
		
		for i = 1, oldSize do
			for j = 1, oldSize do 
				self.data[i+offset][j+offset] = oldGrid[i][j]
			end
		end
		
	-- If new grid is smaller, copy in data from centre of old grid
	else	
		local offset = (oldSize - newSize) / 2
		for i = 1, newSize do
			for j = 1, newSize do 
				self.data[i][j] = oldGrid[i + offset][j + offset]
			end
		end
	end	
end