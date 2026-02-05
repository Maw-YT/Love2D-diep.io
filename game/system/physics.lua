-- game/system/physics.lua
local Physics = {}

-- Ported from Object.ts: The relationship where friction eventually 
-- counters acceleration to create a "top speed".
FRICTION = 0.05 

-- GRID SYSTEM
function Physics.newGrid(shapes, cellSize)
    local grid = {}
    for i = 1, #shapes do
        local s = shapes[i]
        -- Calculate which cell the shape's center is in
        local gx = math.floor(s.x / cellSize)
        local gy = math.floor(s.y / cellSize)
        
        if not grid[gx] then grid[gx] = {} end
        if not grid[gx][gy] then grid[gx][gy] = {} end
        
        table.insert(grid[gx][gy], s)
    end
    return grid
end

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

function Physics.checkShapeCollisionsOptimized(grid, cellSize, dt)
    -- Instead of iterating the shapes list, we iterate the grid cells
    for gx, columns in pairs(grid) do
        for gy, cell in pairs(columns) do
            -- For every shape in this specific cell...
            for i = 1, #cell do
                local s1 = cell[i]
                local r1 = s1:getRadius()

                -- Check the 3x3 grid area around this cell
                for x = gx - 1, gx + 1 do
                    if grid[x] then
                        for y = gy - 1, gy + 1 do
                            local neighborCell = grid[x][y]
                            if neighborCell then
                                for j = 1, #neighborCell do
                                    local s2 = neighborCell[j]
                                    
                                    -- Optimization: Avoid double-checking and self-collision
                                    -- Using the unique memory address to ensure s1 != s2
                                    if s1 ~= s2 then
                                        local dx, dy = s2.x - s1.x, s2.y - s1.y
                                        local distSq = dx*dx + dy*dy
                                        local min = r1 + s2:getRadius()

                                        if distSq < min*min then
                                            applyKnockback(s1, s2, dt)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- 2. Drone vs Drone (Repulsion)
function Physics.checkDroneCollisions(bullets, dt)
    for i = 1, #bullets do
        local d1 = bullets[i]
        if d1.type == "drone" or d1.type == "factoryDrone" then
            for j = i + 1, #bullets do
                local d2 = bullets[j]
                if d2.type == "drone" or d2.type == "factoryDrone" then
                    local dx, dy = d2.x - d1.x, d2.y - d1.y
                    local distSq = dx*dx + dy*dy
                    local min = d1.radius + d2.radius
                    
                    if distSq < min*min then
                        applyKnockback(d1, d2, dt)
                    end
                end
            end
        end
    end
end

-- Bullet/Drone vs Shape
function Physics.checkBulletShapeCollisions(bullets, shapes, game, dt, grid, cellSize)
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        local gx = math.floor(b.x / cellSize)
        local gy = math.floor(b.y / cellSize)

        local collisionFound = false

        -- Check 3x3 grid around bullet
        for x = gx - 1, gx + 1 do
            if grid[x] then
                for y = gy - 1, gy + 1 do
                    local cell = grid[x][y]
                    if cell then
                        for j = #cell, 1, -1 do
                            local s = cell[j]
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
                                    b.player.xp = b.player.xp + (s.max_health * 10)
                                    if b.player:convertShapeToDrone(s) == nil then
                                        s.deathAnim = game.res.Animation:new(s)
                                        table.insert(game.dyingObjects, s)
                                    end
                                    -- Remove from master list
                                    for idx, mainShape in ipairs(shapes) do
                                        if mainShape == s then
                                            table.remove(shapes, idx)
                                            break
                                        end
                                    end
                                end

                                if b.isdead then 
                                    collisionFound = true
                                    break 
                                end
                            end
                        end
                    end
                    if collisionFound then break end
                end
            end
            if collisionFound then break end
        end
    end
end

-- 4. Player vs Shape (Optimized with Spatial Hash)
function Physics.checkPlayerShapeCollisions(player, shapes, game, dt, grid, cellSize)
    local gx = math.floor(player.x / cellSize)
    local gy = math.floor(player.y / cellSize)

    -- Check the 3x3 grid area around the player
    for x = gx - 1, gx + 1 do
        if grid[x] then
            for y = gy - 1, gy + 1 do
                local cell = grid[x][y]
                if cell then
                    -- Iterate backwards to allow removal from the main 'shapes' table
                    for i = #cell, 1, -1 do
                        local s = cell[i]
                        local dx, dy = s.x - player.x, s.y - player.y
                        local distSq = dx*dx + dy*dy
                        local min = player.radius + s:getRadius()

                        if distSq < min*min then
                            applyKnockback(player, s, dt)
                            applyKnockback(s, player, dt)

                            if player.lifeTime > 3 then
                                local bodyDamage = 0.5 + (player.stats.body_damage * 0.5)
                                local playerDamage = 0.5 * (1 - (player.stats.body_damage * 0.1))
                                
                                player.health = player.health - playerDamage
                                s.health = s.health - bodyDamage
                                player.hitTimer, s.hitTimer = 0.2, 0.2

                                if s.health <= 0 then
                                    player.xp = player.xp + (s.max_health * 10)
                                    if player:convertShapeToDrone(s) == nil then
                                        s.deathAnim = game.res.Animation:new(s)
                                        table.insert(game.dyingObjects, s)
                                    end
                                    -- Find and remove from the master shapes table
                                    for idx, mainShape in ipairs(shapes) do
                                        if mainShape == s then
                                            table.remove(shapes, idx)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

return Physics