local FactoryDrone = {}
FactoryDrone.__index = FactoryDrone

local Physics = require "game.system.physics"
local Barrel = require "game.entities.tank.barrel"
local Classes = require "game.data.classes"

function FactoryDrone:new(player, x, y, vx, vy)
    local self = setmetatable({}, FactoryDrone)
    self.player = player  -- The actual player who owns this drone
    self.PlayerClass = player.tankName
    self.x, self.y = x, y
    self.vx, self.vy = vx, vy
    
    -- Factory drone acts as its own "player" for barrel purposes
    self.angle = 0  -- Required by barrel
    self.radius = (player.radius * 0.85) / 2  -- Set this before barrels
    self.stats = player.stats  -- Share player's stats for bullet calculations
    self.bullets = {}  -- Factory drone's own bullets list
    
    -- Factory drones are larger and more durable
    self.speed = 200
    self.turnSpeed = 6
    self.type = "factoryDrone"
    self.lifetime = 15.0  -- Longer lifetime
    self.age = 0
    self.penetration = 2  -- More penetration than regular drones
    self.damage = 8  -- Higher damage
    self.pushFactor = 2.5
    self.absorptionFactor = 1.8

    -- Load the texture here
    self.sprite = love.graphics.newImage("assets/TVRZ.png")
    
    -- Get dimensions to help with centering later
    self.imgWidth = self.sprite:getWidth()
    self.imgHeight = self.sprite:getHeight()
    
    -- Create a mini barrel for the factory drone
    self.barrels = {}
    local barrelConfig = {
        xOffset = 0,
        yOffsetMult = 0.4,
        delay = 0,
        type = "bullet",
    }
    table.insert(self.barrels, Barrel:new(self.player, 0, "bullet", barrelConfig, self))
    
    -- Fire rate control
    self.fire_rate = 1.5
    self.fire_timer = 0
    
    return self
end

function FactoryDrone:update(dt, arena, cam)
    -- Target selection (similar to regular drones)
    local targetX, targetY = self.player.x, self.player.y
    local mx, my = love.mouse.getPosition()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local wx = (mx - sw / 2) / cam.scale + cam.x + (sw / 2) / cam.scale
    local wy = (my - sh / 2) / cam.scale + cam.y + (sh / 2) / cam.scale

    if love.mouse.isDown(1) and not love.keyboard.isDown("lctrl") then
        targetX, targetY = wx, wy
    else
        -- Auto-hunt shapes
        local closestDist = 600
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

        -- Strafing movement: maintain distance and circle around target
    local dx = targetX - self.x
    local dy = targetY - self.y
    local distToTarget = math.sqrt(dx*dx + dy*dy)
    
    -- Optimal combat range (stay at this distance from target)
    local optimalRange = 250
    
    -- Calculate desired position
    local desiredX, desiredY
    
    if distToTarget < optimalRange then
        -- Too close: move away while strafing
        local angleToTarget = math.atan2(dy, dx)
        local strafeAngle = angleToTarget + math.pi/2  -- Perpendicular for strafing
        
        -- Blend between moving away and strafing
        local retreatFactor = (optimalRange - distToTarget) / optimalRange
        retreatFactor = math.min(retreatFactor, 1.0)
        
        desiredX = self.x + (math.cos(angleToTarget + math.pi) * retreatFactor + math.cos(strafeAngle) * (1 - retreatFactor)) * self.speed * dt
        desiredY = self.y + (math.sin(angleToTarget + math.pi) * retreatFactor + math.sin(strafeAngle) * (1 - retreatFactor)) * self.speed * dt
    elseif distToTarget > optimalRange * 1.5 then
        -- Too far: move towards target while strafing
        local angleToTarget = math.atan2(dy, dx)
        local strafeAngle = angleToTarget + math.pi/2
        
        -- Blend between moving toward and strafing
        local approachFactor = (distToTarget - optimalRange * 1.5) / optimalRange
        approachFactor = math.min(approachFactor, 1.0)
        
        desiredX = self.x + (math.cos(angleToTarget) * approachFactor + math.cos(strafeAngle) * (1 - approachFactor)) * self.speed * dt
        desiredY = self.y + (math.sin(angleToTarget) * approachFactor + math.sin(strafeAngle) * (1 - approachFactor)) * self.speed * dt
    else
        -- At good range: pure strafing
        local angleToTarget = math.atan2(dy, dx)
        local strafeAngle = angleToTarget + math.pi/2
        
        -- Alternate strafing direction based on time for more natural movement
        local strafeDir = math.sin(self.age * 2) * 2  -- Change direction periodically
        local finalStrafeAngle = strafeAngle + strafeDir
        
        desiredX = self.x + math.cos(finalStrafeAngle) * self.speed * dt
        desiredY = self.y + math.sin(finalStrafeAngle) * self.speed * dt
    end
    
    -- Calculate desired velocity
    local desiredVx = (desiredX - self.x) / dt
    local desiredVy = (desiredY - self.y) / dt
    
    -- Update angle for barrel to always face target
    self.angle = math.atan2(targetY - self.y, targetX - self.x)
    
    -- Apply steering towards desired velocity
    local steeringPower = self.turnSpeed
    local currentSpeedSq = self.vx*self.vx + self.vy*self.vy
    if currentSpeedSq > (self.speed * 1.5)^2 then
        steeringPower = self.turnSpeed * 0.3
    end

    local multiplier = love.keyboard.isDown("lshift") and -1 or 1
    self.vx = self.vx + (desiredVx * multiplier - self.vx) * steeringPower * dt
    self.vy = self.vy + (desiredVy * multiplier - self.vy) * steeringPower * dt

    Physics.applyPhysics(self, dt)
    
    -- Factory drone shooting using barrel system
    self.fire_timer = self.fire_timer - dt
    if self.fire_timer <= 0 then
        self.fire_timer = self.fire_rate
        
        -- Fire using the barrel system
        for _, barrel in ipairs(self.barrels) do
            local bullet = barrel:fire()
            if bullet then
                -- Override some bullet properties for factory drone mini bullets
                bullet.radius = bullet.radius * 0.6
                bullet.damage = 3
                bullet.lifetime = 2.0
                
                -- Add to player's bullets instead of drone's own bullets
                table.insert(self.player.bullets, bullet)
            end
        end
    end
    
    -- Lifetime check
    self.age = self.age + dt
    if self.age >= self.lifetime then
        self.isdead = true
    end
end

function FactoryDrone:draw(alpha, style)
    local a = (alpha or 1) * (self.player.invisAlpha or 1)
    local dt = love.timer.getDelta()
    
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    -- Draw the barrel
    for _, barrel in ipairs(self.barrels) do
        barrel:draw(a, dt, style)
    end

    -- Draw circle
    local r = self.radius
    local isntTVRZ = self.PlayerClass ~= "TVRZ"
    local spriteScale = (self.radius * 2.5) / self.imgWidth
    if isntTVRZ then
        love.graphics.setLineJoin("bevel")
        love.graphics.setColor(self.player.color[1], self.player.color[2], self.player.color[3], a)

        love.graphics.circle("fill", 0, 0, r)
        
        love.graphics.setLineWidth(2)
        love.graphics.setColor(self.player.outline_color[1], self.player.outline_color[2], self.player.outline_color[3], a)
        love.graphics.circle("line", 0, 0, r)

        love.graphics.setLineJoin("miter")
    else
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.draw(
            self.sprite, 
            0, 0,           -- Position (0,0 because we translated to self.x, self.y)
            0,              -- Rotation (0 because we rotated the whole coordinate system)
            spriteScale, spriteScale,           -- Scale (1.0 = 100% size)
            self.imgWidth/2, self.imgHeight/2 -- Offset (centers the image on the drone's position)
        )
    end
    
    love.graphics.pop()
end

return FactoryDrone