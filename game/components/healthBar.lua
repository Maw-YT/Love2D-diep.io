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
    return self
end

function HealthBar:update(dt, currentHealth, maxHealth)
    self.current = currentHealth
    self.max = maxHealth
    -- Smoothly interpolate the display bar toward actual health
    if self.displayHealth > self.current then
        self.displayHealth = self.displayHealth - (self.displayHealth - self.current) * 10 * dt
    end
end

function HealthBar:draw(x, y, radius, alpha)
    local a = alpha or 1
    if a <= 0 then return end
    
    -- Only draw if health is not full
    if self.current >= self.max and a >= 1 then return end

    local bx = x - self.width / 2
    local by = y + radius + 10

    -- Background (Dark)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8 * a)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", bx, by, self.width, self.height, 2)
    love.graphics.setColor(0.2, 0.2, 0.2, 1 * a)
    love.graphics.rectangle("fill", bx, by, self.width, self.height, 2)
    love.graphics.setLineWidth(1)

    -- "Lazy" Health (White catch-up) - Clamped at 0
    love.graphics.setColor(1, 0, 0, 0.5 * a)
    local lazyPct = math.max(0, self.displayHealth) / self.max
    local lazyWidth = lazyPct * self.width
    love.graphics.rectangle("fill", bx, by, lazyWidth, self.height, 2)

    -- Current Health (Green) - Clamped at 0
    love.graphics.setColor(0.3, 0.9, 0.3, a)
    local healthPct = math.max(0, self.current) / self.max
    local healthWidth = healthPct * self.width
    if healthPct > 0 then
        love.graphics.rectangle("fill", bx, by, healthWidth, self.height, 2)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

return HealthBar