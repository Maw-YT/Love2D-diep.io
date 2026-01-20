-- game/system/camera.lua
local Camera = {}
Camera.__index = Camera

function Camera:new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.speed = 5 -- Higher = snappier, Lower = lazier
    return self
end

function Camera:follow(tx, ty, dt)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Target position (where the camera wants to be)
    local targetX = tx - w/2
    local targetY = ty - h/2

    -- Linear Interpolation: Move part of the way to the target
    -- Formula: current + (target - current) * speed * dt
    self.x = self.x + (targetX - self.x) * self.speed * dt
    self.y = self.y + (targetY - self.y) * self.speed * dt
end

function Camera:apply()
    love.graphics.translate(-self.x, -self.y)
end

return Camera