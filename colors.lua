    
--[[
    colors.lua
    Contains helper functions for color manipulation and drawing gradients.

    Contains:
    - getRGB       Get RGB colors given hue and (dark) mode
    - nextHue:     Cycles through theme colors.
    - gradient:    Creates a gradient image from a table of colors.
    - drawinrect:  Draws an image scaled to fit a rectangle.
    - HSL:         Converts HSL color values to RGB.
]]

-- @hue : Integer
-- @dark : boolean
-- Takes a hue value, and increments it, wrapping around 255
-- Returns updated hue and table with equivalent RGB values
function nextHue(hue, dark)
	local newHue = (hue + 16) % 255
	local newRGB = getRGB(newHue, dark)
	return newHue, newRGB
end

-- @hue : Integer
-- @dark : boolean
-- @saturation : number (optional, default 0.85)
-- @lightness : number (optional, default based on dark)
-- Takes a hue value and returns RGB, adjusted as per dark mode
function getRGB(hue, dark, saturation, lightness)
    saturation = saturation or 0.85          -- default saturation
    local l = lightness or (dark and 0.6 or 0.4)  -- use passed lightness or default
    local r,g,b,a = HSL(hue/256, saturation, l)
    local rgb = {r,g,b, 1}
    return rgb
end



-- https://love2d.org/wiki/Gradients
function gradient(colors)

    local direction = colors.direction or "horizontal"
    if direction == "horizontal" then
        direction = true
    elseif direction == "vertical" then
        direction = false
    else
        error("Invalid direction '" .. tostring(direction) .. "' for gradient.  Horizontal or vertical expected.")
    end
    local result = love.image.newImageData(direction and 1 or #colors, direction and #colors or 1)
    for i, color in ipairs(colors) do
        local x, y
        if direction then
            x, y = 0, i - 1
        else
            x, y = i - 1, 0
        end
        result:setPixel(x, y, color[1], color[2], color[3], color[4] or 255)
    end
    local result = love.graphics.newImage(result)
    result:setFilter('linear', 'linear')
    return result
end


-- https://love2d.org/wiki/Gradients
function drawinrect(img, x, y, w, h, r, ox, oy, kx, ky)	
    return -- tail call for a little extra bit of efficiency
    love.graphics.draw(img, x, y, r, w / img:getWidth(), h / img:getHeight(), ox, oy, kx, ky)
end


-- Converts HSL to RGB. (input and output range: 0 - 1)
-- By love2d.org/wiki/User:Taehl
function HSL(h, s, l, a)
	if s<=0 then return l,l,l,a end
	h, s, l = h * 6, s, l
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return     r+m, g+m, b+m, a
end


return {
    nextHue = nextHue,
    gradient = gradient,
    drawinrect = drawinrect,
    getRGB = getRGB
}