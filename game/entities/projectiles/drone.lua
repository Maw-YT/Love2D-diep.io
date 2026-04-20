local EntityBase = require "game.native.entityBase"
local Drone = setmetatable({}, { __index = EntityBase })
Drone.__index = Drone

local Physics = require "game.system.physics"
local function isEnemy(owner, target)
    if not owner or not target then return false end
    if owner == target then return false end
    if owner.team == nil or target.team == nil then return true end
    return owner.team ~= target.team
end

function Drone:new(player, x, y, vx, vy, droneType)
    local self = EntityBase:new({
        type = "drone",
        team = (player and player.team) or player,
        owner = player,
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        radius = (player.radius * 0.7) / 2,
        angle = 0,
    })
    setmetatable(self, Drone)
    self.player = player
    
    self.speed = 250
    self.turnSpeed = 8
    self.lifetime = 10.0
    self.age = 0
    self.droneType = droneType or "triangle"
    self.penetration = 1
    self.damage = 5
    self.drag_strength = 10
    self.pushFactor = 3.5
    self.absorptionFactor = 1.4
    return self
end

function Drone:update(dt, arena, cam)
    local targetX, targetY = self.player.x, self.player.y
    if self.player and self.player.type == "boss" then
        local closestDist = 900
        if arena and arena.player and not arena.player.isDead and isEnemy(self.player, arena.player) then
            local dx = arena.player.x - self.x
            local dy = arena.player.y - self.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < closestDist then
                closestDist = dist
                targetX, targetY = arena.player.x, arena.player.y
            end
        end
        if arena and arena.bots then
            for _, bot in ipairs(arena.bots) do
                if bot.health > 0 and isEnemy(self.player, bot) then
                    local dx = bot.x - self.x
                    local dy = bot.y - self.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < closestDist then
                        closestDist = dist
                        targetX, targetY = bot.x, bot.y
                    end
                end
            end
        end
    else
        local mx, my = love.mouse.getPosition()
        local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
        local wx = (mx - sw / 2) / cam.scale + cam.x + (sw / 2) / cam.scale
        local wy = (my - sh / 2) / cam.scale + cam.y + (sh / 2) / cam.scale

        if love.mouse.isDown(1) and not love.keyboard.isDown("lctrl") then
            targetX, targetY = wx, wy
        else
            local closestDist = 800
            if arena and arena.shapes then
                for _, s in ipairs(arena.shapes) do
                    local dx = s.x - self.x
                    local dy = s.y - self.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist < closestDist then
                        closestDist = dist
                        targetX, targetY = s.x, s.y
                    end
                end
            end
        end
    end

    local angleToTarget = math.atan2(targetY - self.y, targetX - self.x)
    local multiplier = 1
    if not (self.player and self.player.type == "boss") then
        multiplier = love.keyboard.isDown("lshift") and -1 or 1
    end
    local targetVx = math.cos(angleToTarget) * self.speed * multiplier
    local targetVy = math.sin(angleToTarget) * self.speed * multiplier

    local steeringPower = self.turnSpeed
    local currentSpeedSq = self.vx*self.vx + self.vy*self.vy
    if currentSpeedSq > (self.speed * 1.5)^2 then
        steeringPower = self.turnSpeed * 0.3
    end

    self.vx = self.vx + (targetVx - self.vx) * steeringPower * dt
    self.vy = self.vy + (targetVy - self.vy) * steeringPower * dt

    Physics.applyPhysics(self, dt)
      
    self.age = self.age + dt
    if self.age >= self.lifetime then
        self:setDead(true)
    end
end

function Drone:draw(alpha)
    local a = (alpha or 1) * (self.player.invisAlpha or 1)
    local angle = math.atan2(self.vy, self.vx)
    
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(angle)
    
    love.graphics.setLineJoin("bevel")
    love.graphics.setColor(self.player.color[1], self.player.color[2], self.player.color[3], a)

    if self.droneType == "square" then
        local r = self.radius
        love.graphics.rectangle("fill", -r, -r, r*2, r*2)
        
        love.graphics.setLineWidth(2)
        love.graphics.setColor(self.player.outline_color[1], self.player.outline_color[2], self.player.outline_color[3], a)
        love.graphics.rectangle("line", -r, -r, r*2, r*2)
    else
        local nose = self.radius
        local back = -self.radius * 0.5
        local wing = self.radius * 0.9

        love.graphics.polygon("fill", nose, 0, back, -wing, back, wing)
        
        love.graphics.setLineWidth(2)
        love.graphics.setColor(self.player.outline_color[1], self.player.outline_color[2], self.player.outline_color[3], a)
        love.graphics.polygon("line", nose, 0, back, -wing, back, wing)
    end
    
    love.graphics.setLineJoin("miter")
    love.graphics.pop()
end

return Drone
