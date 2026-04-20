-- game/system/healthBar.lua
local HealthBar = {}
HealthBar.__index = HealthBar

function HealthBar:new(maxHealth)
    local self = setmetatable({}, HealthBar)
    self.max = maxHealth
    self.current = maxHealth
    self.displayHealth = maxHealth -- For the "lazy" catch-up effect
    self.width = 40
    self.height = 6

    -- Fade-in animation state
    self.fadeAlpha = 0  -- Start invisible
    self.fadeSpeed = 5  -- Fade in over ~0.2 seconds
    return self
end

function HealthBar:update(dt, currentHealth, maxHealth)
    self.current = currentHealth
    self.max = maxHealth
    -- Smoothly interpolate the display bar toward actual health
    if self.displayHealth > self.current then
        self.displayHealth = self.displayHealth - (self.displayHealth - self.current) * 10 * dt
    end

    -- Fade in when health is not full
    if self.current < self.max then
        self.fadeAlpha = math.min(1, self.fadeAlpha + self.fadeSpeed * dt)
    else
        -- Fade out when health is full
        self.fadeAlpha = math.max(0, self.fadeAlpha - self.fadeSpeed * dt)
    end
end

function HealthBar:draw(x, y, radius, alpha)  
    local a = (alpha or 1) * self.fadeAlpha  -- Combine with fade alpha
    if a <= 0 then return end  
      
    -- Skip drawing if fully faded out
    if self.fadeAlpha <= 0.01 then return end
  
    -- Scale width based on entity radius (2x radius = diameter)  
    local barWidth = radius * 2  
    local bx = x - barWidth / 2  
    local by = y + radius + 10  
  
    -- Background (Dark)  
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8 * a)  
    love.graphics.setLineWidth(3)  
    love.graphics.rectangle("line", bx, by, barWidth, self.height, 2)  
    love.graphics.setColor(0.2, 0.2, 0.2, 1 * a)  
    love.graphics.rectangle("fill", bx, by, barWidth, self.height, 2)  
    love.graphics.setLineWidth(1)  
  
    -- "Lazy" Health (Red catch-up)  
    love.graphics.setColor(1, 0, 0, 0.5 * a)  
    local lazyPct = math.max(0, self.displayHealth) / self.max  
    local lazyWidth = lazyPct * barWidth  
    love.graphics.rectangle("fill", bx, by, lazyWidth, self.height, 2)  
  
    -- Current Health (Green)  
    love.graphics.setColor(0.3, 0.9, 0.3, a)  
    local healthPct = math.max(0, self.current) / self.max  
    local healthWidth = healthPct * barWidth  
    if healthPct > 0 then  
        love.graphics.rectangle("fill", bx, by, healthWidth, self.height, 2)  
    end  
      
    love.graphics.setColor(1, 1, 1, 1)  
end

return HealthBar