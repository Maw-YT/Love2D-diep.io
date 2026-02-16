-- game/system/animation.lua
local Animation = {}
Animation.__index = Animation

function Animation:new(parent)
    local self = setmetatable({}, Animation)
    self.parent = parent
    self.timer = 0
    self.duration = 0.25
    self.maxScale = 1.5
    self.alpha = 1
    self.done = false
    return self
end

function Animation:update(dt)
    self.timer = self.timer + dt
    local progress = self.timer / self.duration

    -- Calculate transparency (fades to 0)
    self.alpha = 1 - progress
    
    -- Calculate scale (grows from 1 to 1.5)
    self.scale = 1 + (self.maxScale - 1) * progress

    if self.timer >= self.duration then
        self.done = true
    end
end

-- This wraps the drawing code of the parent to apply the effects
function Animation:apply(drawFunc)
    love.graphics.setColor(1, 1, 1, self.alpha)
    love.graphics.push()
        -- Scale from the center of the object
        love.graphics.translate(self.parent.x, self.parent.y)
        love.graphics.scale(self.scale)
        love.graphics.translate(-self.parent.x, -self.parent.y)
        
        drawFunc(self.alpha)
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

return Animation