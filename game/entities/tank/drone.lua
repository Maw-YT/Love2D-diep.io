local Drone = {}
Drone.__index = Drone

function Drone:new(player, x, y, vx, vy)
    local self = setmetatable({}, Drone)
    self.player = player
    self.x, self.y = x, y
    self.vx, self.vy = vx, vy
    
    self.speed = 250
    self.turnSpeed = 8
    self.radius = 12
    self.type = "drone"
    self.isdead = false
    self.penetration = 1
    self.damage = 5
    self.drag_strength = 10
    return self
end

function Drone:update(dt, arena)
    -- 1. Get Mouse/Target coordinates
    local targetX, targetY = self.player.x, self.player.y
    local mx, my = love.mouse.getPosition()
    local wx = mx + (self.player.x - love.graphics.getWidth()/2)
    local wy = my + (self.player.y - love.graphics.getHeight()/2)
    local foundTarget = false

    if love.mouse.isDown(1) and not love.keyboard.isDown("lctrl") then
        targetX, targetY = wx, wy
    else
        -- 2. AUTO-HUNT: Access shapes from the passed arena object
        local closestDist = 800
        foundTarget = false

        if arena and arena.shapes then
            for _, s in ipairs(arena.shapes) do
                local dx = s.x - self.x
                local dy = s.y - self.y
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist < closestDist then
                    closestDist = dist
                    targetX, targetY = s.x, s.y
                    foundTarget = true
                end
            end
        end
    end

    -- 3. Steering and Movement Math (Equilateral Triangle geometry)
    local angleToTarget = math.atan2(targetY - self.y, targetX - self.x)
    local targetVx = nil
    local targetVy = nil
    if not love.keyboard.isDown("lshift") then
        targetVx = math.cos(angleToTarget) * self.speed
        targetVy = math.sin(angleToTarget) * self.speed
    else
        targetVx = -math.cos(angleToTarget) * self.speed
        targetVy = -math.sin(angleToTarget) * self.speed
    end

    self.vx = self.vx + (targetVx - self.vx) * self.turnSpeed * dt
    self.vy = self.vy + (targetVy - self.vy) * self.turnSpeed * dt

    -- Friction
    local speed = math.sqrt(self.vx*self.vx + self.vy*self.vy)
    if speed > 0.1 then
        local drag_mag = self.drag_strength * speed * dt
        self.vx = self.vx - (self.vx / speed) * drag_mag
        self.vy = self.vy - (self.vy / speed) * drag_mag
    else
        self.vx, self.vy = 0, 0
    end

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function Drone:draw(alpha)
    local a = alpha or 1
    local angle = math.atan2(self.vy, self.vx)
    
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(angle)
    
    -- TRIANGLE MATH:
    -- Nose is at (radius, 0)
    -- Back corners are at (-radius/2, -radius) and (-radius/2, radius)
    -- This creates a balanced equilateral-style triangle.
    local nose = self.radius
    local back = -self.radius * 0.5
    local wing = self.radius * 0.9

    love.graphics.setLineJoin("bevel")
    -- Draw Fill
    love.graphics.setColor(self.player.color[1], self.player.color[2], self.player.color[3], a)
    love.graphics.polygon("fill", 
        nose, 0,    -- Front tip
        back, -wing, -- Top back
        back, wing   -- Bottom back
    )
    
    -- Draw Outline
    love.graphics.setLineWidth(2)
    love.graphics.setColor(self.player.outline_color[1], self.player.outline_color[2], self.player.outline_color[3], a)
    love.graphics.polygon("line", 
        nose, 0, 
        back, -wing, 
        back, wing
    )
    love.graphics.setLineJoin("miter")

    love.graphics.pop()
end

return Drone