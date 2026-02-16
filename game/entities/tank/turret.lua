local Turret = {}
Turret.__index = Turret

function Turret:new(parent, config)
    local self = setmetatable({}, Turret)
    
    -- References
    self.parent = parent -- The Player object
    self.res = parent.res -- Share the same loader resources
    
    -- Transform
    self.x = parent.x
    self.y = parent.y
    self.offsetX = config.x or 0
    self.offsetY = config.y or 0
    self.angle = 0
    self.config = config
    self.radius = parent.radius * config.size
    
    -- Stats & Config
    self.config = config
    self.fire_rate = config.fire_rate or 0.5
    self.fire_timer = 0
    self.range = config.range or 500
    
    -- Visuals
    self.color = config.color or {0.6, 0.6, 0.6} -- Gray by default
    self.outline_color = {0.4, 0.4, 0.4}
    
    -- Barrel Setup (Matches Player's barrel logic)
    self.barrels = {}
    if config.barrels then
        for _, b in ipairs(config.barrels) do
            table.insert(self.barrels, self.res.Barrel:new(self.parent, b.delay, b.type, b, self))
        end
    end

    return self
end

function Turret:update(dt, arena, targets)
    self.x = self.parent.x + self.offsetX
    self.y = self.parent.y + self.offsetY
    self.radius = self.parent.radius * self.config.size
    -- 1. Aiming Logic: Find closest target (e.g., shapes or enemies)
    local target = self:findTarget(targets)
    
    if target then
        local targetAngle = math.atan2(target.y - self.y, target.x - self.x)
        -- Smooth rotation (optional, or snap to target)
        self.angle = targetAngle
        
        -- 2. Firing Logic
        self.fire_timer = self.fire_timer - dt
        if self.fire_timer <= 0 then
            self.fire_timer = self.fire_rate
            for _, b in ipairs(self.barrels) do
                -- Fire and inject into the parent's bullet list
                table.insert(self.parent.bullets, b:fire())
            end
        end
    else
        -- Idle behavior: slow spin or reset
        self.angle = self.angle + (0.5 * dt)
    end
end

function Turret:findTarget(targets)
    local nearest = nil
    local minDist = self.range
    
    for _, t in ipairs(targets) do
        local dist = math.sqrt((t.x - self.x)^2 + (t.y - self.y)^2)
        if dist < minDist then
            minDist = dist
            nearest = t
        end
    end
    return nearest
end

function Turret:draw(alpha, style)
    -- Barrel Push
    love.graphics.push()
    love.graphics.translate(self.parent.x + self.offsetX, self.parent.y + self.offsetY)
    love.graphics.rotate(self.angle)
    -- Draw Barrels
    for _, barrel in ipairs(self.barrels) do
        barrel:draw(alpha, love.timer.getDelta(), style)
    end
    -- Draw Turret Base
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.circle("fill", 0, 0, self.radius)
    
    love.graphics.setLineWidth(3)
    love.graphics.setColor(self.outline_color[1], self.outline_color[2], self.outline_color[3], alpha)
    love.graphics.circle("line", 0, 0, self.radius)
    love.graphics.pop()
end

return Turret