-- game/system/camera.lua
local Camera = {}
Camera.__index = Camera

function Camera:new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.scale = 1 -- Current zoom level
    self.speed = 5 
    return self
end

function Camera:follow(tx, ty, dt, targetScale)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Smoothly interpolate the zoom scale
    self.scale = self.scale + (targetScale - self.scale) * self.speed * dt

    -- Target position: The player's interpolated visual position
    -- Note: tx and ty should be the PLAYER'S interpolated draw coordinates
    local targetX = tx - (w / 2) / self.scale
    local targetY = ty - (h / 2) / self.scale

    -- Standard camera smoothing
    self.x = self.x + (targetX - self.x) * self.speed * dt
    self.y = self.y + (targetY - self.y) * self.speed * dt
end

function Camera:apply()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- 1. Move to screen center
    love.graphics.translate(w/2, h/2)
    -- 2. Scale the world
    love.graphics.scale(self.scale)
    -- 3. Move back by camera coordinates
    love.graphics.translate(-self.x - (w/2) / self.scale, -self.y - (h/2) / self.scale)
end

return Camera