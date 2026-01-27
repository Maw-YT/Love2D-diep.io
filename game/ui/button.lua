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
    
    return self
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
    
    -- Draw outline
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 2)
    
    -- Draw text centered
    love.graphics.setColor(self.textColor)
    local font = love.graphics.getFont()
    local textW = font:getWidth(self.text)
    local textH = font:getHeight()
    
    love.graphics.print(self.text, 
        self.x + (self.width / 2) - (textW / 2), 
        self.y + (self.height / 2) - (textH / 2)
    )
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset
end

function Button:mousepressed(x, y, button)
    if self.isHovered and button == 1 then
        self.callback()
        return true -- Button handled the click
    end
    return false
end

return Button