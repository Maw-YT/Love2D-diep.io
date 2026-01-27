-- game/system/physics.lua
local Physics = {}

-- Ported from Object.ts: The relationship where friction eventually 
-- counters acceleration to create a "top speed".
local FRICTION = 0.1 

-- 1. Internal Physics (Ported from Object.ts: applyPhysics)
-- Call this for every entity in your update loop
function Physics.applyPhysics(obj, dt)
    -- If the object is dying, it slows down significantly
    local decay = obj.isDead and 0.5 or 1.0
    
    -- Update position based on velocity
    obj.x = obj.x + (obj.vx * dt)
    obj.y = obj.y + (obj.vy * dt)

    -- Apply friction opposite of current velocity
    -- In Object.ts, this is: velocity += velocity * -0.1
    obj.vx = obj.vx - (obj.vx * FRICTION * decay)
    obj.vy = obj.vy - (obj.vy * FRICTION * decay)

    -- Stop tiny movements to save performance
    if math.abs(obj.vx) < 0.01 then obj.vx = 0 end
    if math.abs(obj.vy) < 0.01 then obj.vy = 0 end
end

-- 2. Arena Bounds (Ported from Object.ts: keepInArena)
function Physics.keepInArena(obj, mapWidth, mapHeight)
    local padding = 50 -- Equivalent to ARENA_PADDING
    
    if obj.x < -padding then obj.x = -padding
    elseif obj.x > mapWidth + padding then obj.x = mapWidth + padding end
    
    if obj.y < -padding then obj.y = -padding
    elseif obj.y > mapHeight + padding then obj.y = mapHeight + padding end
end

-- 3. Core Knockback Logic (Ported from Object.ts: receiveKnockback)
local function applyKnockback(objA, objB, dt)
    -- Calculate magnitude using the factor-based system
    -- absorptionFactor: How much the object is affected by hits
    -- pushFactor: How much "shove" the other object has
    local absorption = objA.absorptionFactor or 1
    local push = objB.pushFactor or 1
    local kbMagnitude = (absorption * push) * 500 * dt

    local dx, dy = objA.x - objB.x, objA.y - objB.y
    local angle
    
    -- Prevent stacking if coordinates are identical
    if dx == 0 and dy == 0 then
        angle = love.math.random() * math.pi * 2
    else
        angle = math.atan2(dy, dx)
    end

    objA.vx = objA.vx + math.cos(angle) * kbMagnitude
    objA.vy = objA.vy + math.sin(angle) * kbMagnitude
end

--- COLLISION HANDLERS ---

-- Shape vs Shape
function Physics.checkShapeCollisions(shapes, dt)
    for i = 1, #shapes do
        for j = i + 1, #shapes do
            local s1, s2 = shapes[i], shapes[j]
            local dx, dy = s2.x - s1.x, s2.y - s1.y
            local distSq = dx*dx + dy*dy
            local min = s1:getRadius() + s2:getRadius()

            if distSq < min*min then
                applyKnockback(s1, s2, dt)
                applyKnockback(s2, s1, dt)
            end
        end
    end
end

-- 2. Drone vs Drone (Repulsion)
function Physics.checkDroneCollisions(bullets, dt)
    for i = 1, #bullets do
        local d1 = bullets[i]
        if d1.type == "drone" then
            for j = i + 1, #bullets do
                local d2 = bullets[j]
                if d2.type == "drone" then
                    local dx, dy = d2.x - d1.x, d2.y - d1.y
                    local distSq = dx*dx + dy*dy
                    local min = d1.radius + d2.radius
                    
                    if distSq < min*min then
                        applyKnockback(d1, d2, dt)
                        applyKnockback(d2, d1, dt)
                    end
                end
            end
        end
    end
end

-- Bullet/Drone vs Shape
function Physics.checkBulletShapeCollisions(bullets, shapes, game, dt)
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        for j = #shapes, 1, -1 do
            local s = shapes[j]
            local dx, dy = b.x - s.x, b.y - s.y
            local distSq = dx*dx + dy*dy
            local min = b.radius + s:getRadius()

            if distSq < min*min then
                applyKnockback(s, b, dt)
                applyKnockback(b, s, dt)
                
                b.penetration = b.penetration - 1
                s.health = s.health - b.damage
                s.hitTimer = 0.2

                if b.penetration <= 0 then b.isdead = true end
                if s.health <= 0 then
                    -- Reward XP and trigger animation
                    b.player.xp = b.player.xp + (s.max_health * 10)
                    s.deathAnim = game.res.Animation:new(s)
                    table.insert(game.dyingObjects, s)
                    table.remove(shapes, j)
                end
                if b.isdead then break end 
            end
        end
    end
end

-- 4. Player vs Shape
function Physics.checkPlayerShapeCollisions(player, shapes, dt)
    for i = #shapes, 1, -1 do
        local s = shapes[i]
        local dx, dy = s.x - player.x, s.y - player.y
        local distSq = dx*dx + dy*dy
        local min = player.radius + s:getRadius()

        if distSq < min*min then
            applyKnockback(player, s, dt)
            applyKnockback(s, player, dt)

            if player.lifeTime > 3 then
                player.health = player.health - 0.5
                player.hitTimer, s.hitTimer = 0.2, 0.2
            end
        end
    end
end

return Physics