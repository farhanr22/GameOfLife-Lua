-- Game of Life in Lua / Love2D

--- Imports ---
require 'math'
require 'os'

Class = require 'lib.class'
push = require 'lib.push'
utils = require('utils')
colors = require('colors')
rle = require('rle')


require 'patterns'
require 'Grid'

--[[
    The Game object stores all of the game objects and variables
    in one place, organized based on their role
]]--

Game = {
    config = {
        WINDOW_WIDTH  = 1088,
        WINDOW_HEIGHT = 600,
        VIRTUAL_WIDTH = 900,
        VIRTUAL_HEIGHT = 600, -- also the height of the actual grid itself
        GRID_SIZES = {20, 30, 50, 60, 100, 120, 150},  -- even factors of VIRTUAL_HEIGHT
        SPEEDS = {1, 5, 10, 15, 30, 60},
        GRID_EFFECTS_THRESHOLD = 60,
        INITIAL_GRID_SIZE = 30,
        INITIAL_SPEED = 15,
        INITIAL_RULE = "B3/S23"
    },
    state = {
        paused = false,
        dark = false,
        speed = 15, -- Initial value
        ruleString = "B3/S23", -- Initial value
        timeElapsed = 0,
        extraInfo = nil,
        currentHue = 0,
        cRGB = {},
        lastCell = "",
        isFirstFrame = true, -- for initial push resize 
    },
    assets = {
        fonts = {},
        sounds = {}
    },
    objects = {
        grid = nil,
        menu = nil
    }
}


-- Text template for the menu
local menuTextTemplate = [=[
+-------- Status --------+
$1
$2
$3
$4
$5
+------------------------+

+------- Controls -------+
| Clear              [C] |
| Next               [N] |
| Randomize          [R] |
| Pause / Play   [Space] |
| Quit             [Esc] |
| Change Hue         [H] |
| Change Speed       [S] |
| Change Grid Size   [G] |
| Change Edge Mode   [M] |
| Dark Mode          [D] |
| Load rulestring    [L] |
| Load pattern       [X] |
| Save pattern       [Y] |
+------------------------+
]=]


function love.load()
    -- Setup virtual resolution
    push:setupScreen(Game.config.VIRTUAL_WIDTH, Game.config.VIRTUAL_HEIGHT, Game.config.WINDOW_WIDTH, Game.config.WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        centered = true
    })

    -- Load assets
    -- Game.assets.fonts.large = love.graphics.newFont('assets/consolas-bold.ttf', 30)
    -- Game.assets.fonts.small = love.graphics.newFont('assets/consolas.ttf', 15)
    Game.assets.fonts.large = love.graphics.newFont('assets/roboto-semibold.ttf', 28)
    Game.assets.fonts.small = love.graphics.newFont('assets/roboto.ttf', 14)
    Game.assets.sounds['blip'] = love.audio.newSource('assets/nice.wav', 'static')
    Game.assets.sounds['click'] = love.audio.newSource('assets/ratchet.wav', 'static')

    -- Initialize state
    Game.state.speed = Game.config.INITIAL_SPEED
    Game.state.ruleString = Game.config.INITIAL_RULE

    -- Initialize color, set rgb values from random hue
    math.randomseed(os.time())
    Game.state.currentHue = math.random() * 255
    _, Game.state.cRGB = colors.nextHue(Game.state.currentHue, Game.state.dark)

    -- Initialize game objects
    local initRuleTable, initRuleString = utils.getRuleTable(Game.state.ruleString)
    Game.state.ruleString = initRuleString -- Ensure it's the formatted version
    local initPattern = rle.load(Game.config.INITIAL_GRID_SIZE, getRandomPattern())
    Game.objects.grid = Grid(Game.config.INITIAL_GRID_SIZE, initRuleTable, initPattern, true)
    Game.objects.menu = love.graphics.newText(Game.assets.fonts.small, menuTextTemplate)

    -- Set mouse cursor
    local cur = love.mouse.getSystemCursor("crosshair")
    love.mouse.setCursor(cur)

    updateMenu()
end


function love.update(dt)
    -- this bit 'initializes' push once the actual rendering starts,
    -- to get the correct dimensions 
    if Game.state.isFirstFrame then
        local w, h = love.graphics.getDimensions()
        push:resize(w, h)
        Game.state.isFirstFrame = false -- Disable the flag so this never runs again.
    end

    local tick = false
    Game.state.timeElapsed = Game.state.timeElapsed + dt
    if Game.state.timeElapsed > (1 / Game.state.speed) then
        Game.state.timeElapsed = 0
        tick = true
    end

    -- Update grid if game is running, mouse is not held down, and enough time has passed
    if not Game.state.paused and not love.mouse.isDown(1) and tick then
        Game.objects.grid:next()
    end

    -- Allow painting with the mouse
    if love.mouse.isDown(1) then
        Game.state.extraInfo = ''
        paint()
    end
end


function love.draw()
    drawGradient() -- Draw background gradient

    push:apply('start') -- Begin drawing in virtual resolution

    -- Draw background rectangle
    darkModeColor(true)
    love.graphics.rectangle('fill', 0, 0, Game.config.VIRTUAL_WIDTH, Game.config.VIRTUAL_HEIGHT)

    -- Draw title
    love.graphics.setFont(Game.assets.fonts.large)
    love.graphics.setColor(unpack(Game.state.cRGB))
    love.graphics.print("CONWAY'S\nGAME OF LIFE", Game.config.VIRTUAL_HEIGHT + 42, 25)

    -- Use the main color but with slightly reduced alpha/opacity for a subtle look
    love.graphics.setFont(Game.assets.fonts.small)
    local c = Game.state.cRGB
    love.graphics.setColor(c[1], c[2], c[3], 0.7) 
    love.graphics.print("github.com/farhanr22/\nGameOfLife-Lua", Game.config.VIRTUAL_HEIGHT + 45, 100)

    -- Draw grid of cells
    renderGrid()

    -- Draw UI elements
    darkModeColor(false)
    drawBorders()
    drawPointerbox()
    -- love.graphics.draw(Game.objects.menu, 642, 85) 
    love.graphics.draw(Game.objects.menu, 642, 155) 


    push:apply('end')
end


function love.mousereleased(x, y, button)
    -- Reset lastCell on mouse release so that user can toggle the same cell repeatedly
    Game.state.lastCell = ''
end

function love.resize(w, h)
    push:resize(w, h)
end


--[[
    This table links each key to a function that runs a game action, 
    better than having a long if chain in love.keypressed
]]
local keyHandlers = {
    ['space'] = function()
        Game.state.paused = not Game.state.paused
        Game.state.extraInfo = nil
    end,
    ['r'] = function()
        Game.objects.grid:randomize()
    end,
    ['c'] = function()
        Game.objects.grid:clear()
    end,
    ['n'] = function()
        Game.objects.grid:next()
    end,
    ['m'] = function()
        Game.objects.grid.wrap = not Game.objects.grid.wrap
    end,
    ['d'] = function()
        Game.state.dark = not Game.state.dark
        Game.state.cRGB = colors.getRGB(Game.state.currentHue, Game.state.dark)
    end,
    ['s'] = function()
        Game.state.speed = utils.nextListValue(Game.config.SPEEDS, Game.state.speed)
    end,
    ['h'] = function()
        Game.state.currentHue, Game.state.cRGB = colors.nextHue(Game.state.currentHue, Game.state.dark)
    end,
    ['g'] = function()
        Game.objects.grid:setGridSize(utils.nextListValue(Game.config.GRID_SIZES, Game.objects.grid.size))
    end,
    ['y'] = function()
        Game.state.paused = true
        rle.save(Game.objects.grid.data)
        Game.state.extraInfo = "Pattern saved :)"
    end,
    ['x'] = function()
        Game.state.paused = true
        Game.objects.grid.oldData = utils.emptyGrid(Game.objects.grid.size)
        local loaded = rle.load(Game.objects.grid.size, love.system.getClipboardText())
        if loaded then
            Game.objects.grid.data = loaded
            Game.state.extraInfo = "Pattern loaded :)"
        else
            Game.state.extraInfo = "Couldn't load :("
        end
    end,
    ['l'] = function()
        Game.state.paused = true
        local ruleTable, rulestr = utils.getRuleTable(love.system.getClipboardText())
        if ruleTable then
            Game.objects.grid.ruleTable = ruleTable
            Game.state.ruleString = rulestr
            Game.state.extraInfo = "Rule applied :)"
        else
            Game.state.extraInfo = "Invalid rule :("
        end
    end
}

    
function love.keypressed(key)
    -- Look for the pressed key in our keyHandlers table
    local handler = keyHandlers[key]

    if handler then
        -- If a handler exists for this key, play a sound and execute it
        Game.assets.sounds['blip']:play()
        handler()
        updateMenu() -- Update the menu since state might have changed
    elseif key == 'escape' then
        -- Close the application
        love.event.quit()
    end
end


-------------------------------------------------
-- Helper Functions
-------------------------------------------------

-- Sets drawing color based on dark mode
function darkModeColor(option)
    if option == Game.state.dark then -- XNOR logic
        love.graphics.setColor(0, 0, 0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
end


-- Toggles value of cell under mouse pointer
function paint()
    local gx, gy = getCellCoords()
    if gx and gy then
        local current = gx .. gy

        -- Prevent same cell from being repeatedly toggled
        if current ~= Game.state.lastCell then
            Game.assets.sounds['click']:play()
            Game.state.lastCell = current
            local currentVal = Game.objects.grid.data[gx][gy]
            Game.objects.grid.data[gx][gy] = (currentVal == 1) and 0 or 1
        end
    end
end


-- Draws the background gradient
function drawGradient()
    local width, height = love.graphics.getDimensions()
    local direction = (width / height > Game.config.VIRTUAL_WIDTH / Game.config.VIRTUAL_HEIGHT) and 'horizontal' or 'vertical'
    local backgroundGradient;
    local c = colors.getRGB(Game.state.currentHue, Game.state.dark, 1, 0.75)

    if Game.state.dark then
        backgroundGradient = colors.gradient {
            direction = direction;
            {c[1], c[2], c[3], 0.5},
            {c[1], c[2], c[3], 0.3},
            {c[1], c[2], c[3], 0.2}
        }
    else
        backgroundGradient = colors.gradient {
        direction = direction;
        {c[1], c[2], c[3], 0.9},
        {c[1], c[2], c[3], 0.7},
        {c[1], c[2], c[3], 0.6}
        }
    end
    colors.drawinrect(backgroundGradient, 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end


-- Draws borders around the main canvas
function drawBorders()
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line', 0, 0, Game.config.VIRTUAL_WIDTH, Game.config.VIRTUAL_HEIGHT)
    love.graphics.setLineWidth(1)
    love.graphics.line(Game.config.VIRTUAL_HEIGHT, 0, Game.config.VIRTUAL_HEIGHT, Game.config.VIRTUAL_HEIGHT)
end


function updateMenu()
    local statusText
    if Game.state.extraInfo and Game.state.extraInfo ~= '' then
        -- If an info message exists, prioritize it
        statusText = Game.state.extraInfo
    else
        -- Otherwise, show the simulation's current state
        statusText = Game.state.paused and "Paused" or "Running"
    end

    local speedText = 'Gen/s: ' .. Game.state.speed
    local sizeText = 'Size: ' .. Game.objects.grid.size .. ' X ' .. Game.objects.grid.size
    local ruleText = 'Rule: ' .. Game.state.ruleString
    local wrapText = 'Mode: ' .. (Game.objects.grid.wrap and 'Torus' or 'Bounded')

    local text = menuTextTemplate
    text = text:gsub('$1', string.format('| %-22s |', (statusText))) -- Use our new variable here
    text = text:gsub('$2', string.format('| %-22s |', (speedText)))
    text = text:gsub('$3', string.format('| %-22s |', (sizeText)))
    text = text:gsub('$4', string.format('| %-22s |', (ruleText)))
    text = text:gsub('$5', string.format('| %-22s |', (wrapText)))

    local color = Game.state.dark and {1, 1, 1} or {0, 0, 0}
    Game.objects.menu:set({color, text})
end


-- Renders the grid, its cells, and optional effects
function renderGrid()
    local grid = Game.objects.grid
    local cell = Game.config.VIRTUAL_HEIGHT / grid.size
    local cRGB = Game.state.cRGB

    -- Draw current generation
    love.graphics.setColor(unpack(cRGB))
    for i = 1, grid.size do
        for j = 1, grid.size do
            if grid.data[i][j] == 1 then
                love.graphics.rectangle('fill', cell * (i - 1), cell * (j - 1), cell, cell)
            end
        end
    end

    -- If grid is small enough, show ghost of previous generation and grid lines
    if not (grid.size > Game.config.GRID_EFFECTS_THRESHOLD) then
        love.graphics.setColor(cRGB[1], cRGB[2], cRGB[3], 0.2)
        for i = 1, grid.size do
            for j = 1, grid.size do
                if grid.oldData[i][j] == 1 then
                    love.graphics.rectangle('fill', cell * (i - 1), cell * (j - 1), cell, cell)
                end
            end
        end

        darkModeColor(true)
        love.graphics.setLineWidth(1)
        for i = 1, grid.size do
            love.graphics.line(cell * i, 0, cell * i, Game.config.VIRTUAL_HEIGHT)
            love.graphics.line(0, cell * i, Game.config.VIRTUAL_HEIGHT, cell * i)
        end
    end
end


-- Draws a box around the cell under the mouse pointer
function drawPointerbox()
    local x, y = getCellCoords()
    if x and y then
        local cell = Game.config.VIRTUAL_HEIGHT / Game.objects.grid.size
        love.graphics.rectangle('line', (x - 1) * cell, (y - 1) * cell, cell, cell)
    end
end


-- Returns the grid coordinates (gx, gy) of the cell the mouse is hovering over
function getCellCoords()
    local mouseX, mouseY = love.mouse.getPosition()
    mouseX, mouseY = push:toGame(mouseX, mouseY)
    
    -- The grid is a square that fills the VIRTUAL_HEIGHT dimension
    local gridSizePixels = Game.config.VIRTUAL_HEIGHT

    if (mouseX and mouseY) and (mouseX >= 0 and mouseX < gridSizePixels) and (mouseY >= 0 and mouseY < gridSizePixels) then
        local cell = gridSizePixels / Game.objects.grid.size
        local gx = math.floor(mouseX / cell) + 1
        local gy = math.floor(mouseY / cell) + 1
        return gx, gy
    end
    return nil, nil
end