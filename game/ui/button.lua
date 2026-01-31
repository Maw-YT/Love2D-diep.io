-- game/system/button.lua
local Button = {}
Button.__index = Button

function Button:new(text, x, y, width, height, callback)
    local self = setmetatable({}, Button)
    self.text = text
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.callback = callback -- The function to run when clicked
    self.isHovered = false
    
    -- Colors
    self.color = {0, 0.45, 0.8}
    self.hoverColor = {0, 0.55, 0.95}
    self.textColor = {1, 1, 1}
    
    -- Highlight/Shadow color (slightly darker than base)
    self.shadowColor = {0, 0, 0, 0.2}   -- Transparent black for the bottom 1/3
    return self
end

local font = love.graphics.newFont("font.ttf", 14)

local function drawOutlinedText(text, x, y, width, align, textColor, outlineColor)
    love.graphics.setFont(font)
    local outline = outlineColor or {0, 0, 0} -- Default to black
    
    love.graphics.setColor(outline)
    -- Draw the text shifted in 8 directions to create the outline
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.printf(text, x + dx, y + dy, width, align)
            end
        end
    end
    
    -- Draw the main text on top
    love.graphics.setColor(textColor)
    love.graphics.printf(text, x, y, width, align)
end

function Button:update(dt)
    local mx, my = love.mouse.getPosition()
    
    -- Check if mouse is within button bounds
    self.isHovered = mx >= self.x and mx <= self.x + self.width and
                     my >= self.y and my <= self.y + self.height
end

function Button:draw()
    -- Switch color based on hover state
    local drawColor = self.isHovered and self.hoverColor or self.color
    love.graphics.setColor(drawColor[1], drawColor[2], drawColor[3])
    
    -- Draw button body (rounded rectangle)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 2)

    -- Draw Shadow (Bottom 1/3)
    love.graphics.setColor(self.shadowColor)
    local shadowHeight = self.height / 3
    love.graphics.rectangle("fill", self.x, self.y + self.height - shadowHeight, self.width, shadowHeight)
    
    -- Draw outline around the button
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 2)
    
    -- Calculate text position for centering
    local font = love.graphics.getFont()
    local textH = font:getHeight()
    local ty = self.y + (self.height / 2) - (textH / 2)
    
    -- Use the outlined text function
    -- We use self.width and "center" to handle the horizontal centering automatically
    drawOutlinedText(self.text, self.x, ty, self.width, "center", self.textColor, {0, 0, 0})
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color for next draw calls
end

function Button:mousepressed(x, y, button)
    if self.isHovered and button == 1 then
        self.callback()
        return true -- Button handled the click
    end
    return false
end

return Button