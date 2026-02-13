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
                                    -- Award XP to any player (human or bot)
                                    b.player.xp = b.player.xp + (s.max_health * 10)
                                    b.player.score = (b.player.score or 0) + (s.max_health * 10)
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

-- Bullet vs single tank (player or bot); returns true if bullet was destroyed
local function bulletHitTank(bullet, tank, dt, game)
    if not tank or (tank.isDead and tank.isDead == true) then return false end
    local dx, dy = tank.x - bullet.x, tank.y - bullet.y
    local distSq = dx * dx + dy * dy
    local min = bullet.radius + tank.radius
    if distSq >= min * min then return false end
    applyKnockback(tank, bullet, dt)
    applyKnockback(bullet, tank, dt)
    tank.health = tank.health - bullet.damage
    tank.hitTimer = 0.2
    bullet.penetration = bullet.penetration - 1
    
    -- Award XP if tank was killed
    if tank.health <= 0 and not tank.isDead and game then
        tank.isDead = true
        tank.deathAnim = game.res.Animation:new(tank)
        table.insert(game.dyingObjects, tank)
        -- Award XP to bullet owner (for player or bot kills)
        if bullet.player and bullet.player.xp ~= nil then
            local xpReward = (tank.max_health or 100) * 12
            bullet.player.xp = bullet.player.xp + xpReward
            bullet.player.score = (bullet.player.score or 0) + xpReward
        end
    end
    
    return bullet.penetration <= 0
end

-- Player bullets vs bots
function Physics.checkPlayerBulletBotCollisions(playerBullets, bots, game, dt)
    for i = #playerBullets, 1, -1 do
        local b = playerBullets[i]
        if b.isdead then goto continue end
        for _, bot in ipairs(bots) do
            if bot.health > 0 and bulletHitTank(b, bot, dt, game) then
                b.isdead = true
                break
            end
        end
        ::continue::
    end
end

-- Bot bullets vs player
function Physics.checkBotBulletPlayerCollisions(bots, player, game, dt)
    if not player or player.isDead then return end
    for _, bot in ipairs(bots) do
        for i = #bot.bullets, 1, -1 do
            local b = bot.bullets[i]
            if not b.isdead and bulletHitTank(b, player, dt, game) then
                b.isdead = true
            end
        end
    end
end

-- Bot bullets vs other bots (bots fight each other)
function Physics.checkBotBulletBotCollisions(bots, game, dt)
    for _, shooter in ipairs(bots) do
        for i = #shooter.bullets, 1, -1 do
            local b = shooter.bullets[i]
            if b.isdead then goto next_bullet end
            for _, other in ipairs(bots) do
                if other ~= shooter and other.health > 0 and bulletHitTank(b, other, dt, game) then
                    b.isdead = true
                    goto next_bullet
                end
            end
            ::next_bullet::
        end
    end
end

-- Bot vs Bot body collision
function Physics.checkBotBotCollisions(bots, game, dt)
    for i = 1, #bots do
        local a = bots[i]
        if a.health <= 0 then goto next_a end
        for j = i + 1, #bots do
            local b = bots[j]
            if b.health <= 0 then goto next_b end
            local dx, dy = b.x - a.x, b.y - a.y
            local distSq = dx * dx + dy * dy
            local min = a.radius + b.radius
            if distSq < min * min then
                applyKnockback(a, b, dt)
                applyKnockback(b, a, dt)
                local dmg = 0.5
                a.health = a.health - dmg
                b.health = b.health - dmg
                a.hitTimer, b.hitTimer = 0.2, 0.2
                
                -- Award XP for kills
                if a.health <= 0 and not a.isDead then
                    a.isDead = true
                    a.deathAnim = game.res.Animation:new(a)
                    table.insert(game.dyingObjects, a)
                    local xpReward = (a.max_health or 100) * 12
                    b.xp = b.xp + xpReward
                    b.score = (b.score or 0) + xpReward
                end
                if b.health <= 0 and not b.isDead then
                    b.isDead = true
                    b.deathAnim = game.res.Animation:new(b)
                    table.insert(game.dyingObjects, b)
                    local xpReward = (b.max_health or 100) * 12
                    a.xp = a.xp + xpReward
                    a.score = (a.score or 0) + xpReward
                end
            end
            ::next_b::
        end
        ::next_a::
    end
end

-- Player vs Bot body collision
function Physics.checkPlayerBotCollisions(player, bots, game, dt)
    if not player or player.isDead then return end
    for _, bot in ipairs(bots) do
        if bot.health <= 0 then goto nextbot end
        local dx, dy = bot.x - player.x, bot.y - player.y
        local distSq = dx * dx + dy * dy
        local min = player.radius + bot.radius
        if distSq < min * min then
            applyKnockback(player, bot, dt)
            applyKnockback(bot, player, dt)
            local bodyDamageP = 0.5 + (player.stats.body_damage * 0.5)
            local playerDamage = 0.5 * (1 - (player.stats.body_damage * 0.1))
            player.health = player.health - playerDamage
            bot.health = bot.health - bodyDamageP
            player.hitTimer, bot.hitTimer = 0.2, 0.2
            
            -- Award XP for kills
            if player.health <= 0 and not player.isDead then
                player.isDead = true
                player.deathAnim = game.res.Animation:new(player)
                table.insert(game.dyingObjects, player)
                local xpReward = (bot.max_health or 100) * 12
                bot.xp = bot.xp + xpReward
                bot.score = (bot.score or 0) + xpReward
            end
            if bot.health <= 0 and not bot.isDead then
                bot.isDead = true
                bot.deathAnim = game.res.Animation:new(bot)
                table.insert(game.dyingObjects, bot)
                local xpReward = (bot.max_health or 100) * 12
                player.xp = player.xp + xpReward
                player.score = (player.score or 0) + xpReward
            end
        end
        ::nextbot::
    end
end

-- Bot vs Shape body collision (bots take damage from ramming shapes)
function Physics.checkBotShapeCollisions(bots, shapes, game, dt, grid, cellSize)
    for _, bot in ipairs(bots) do
        if bot.health <= 0 then goto nextbot end
        local gx = math.floor(bot.x / cellSize)
        local gy = math.floor(bot.y / cellSize)
        for x = gx - 1, gx + 1 do
            if grid[x] then
                for y = gy - 1, gy + 1 do
                    local cell = grid[x][y]
                    if cell then
                        for i = #cell, 1, -1 do
                            local s = cell[i]
                            local dx, dy = s.x - bot.x, s.y - bot.y
                            local distSq = dx * dx + dy * dy
                            local min = bot.radius + s:getRadius()
                            if distSq < min * min then
                                applyKnockback(bot, s, dt)
                                applyKnockback(s, bot, dt)
                                local bodyDmg = 0.5
                                bot.health = bot.health - bodyDmg * 0.5
                                s.health = s.health - bodyDmg
                                bot.hitTimer, s.hitTimer = 0.2, 0.2
                                if s.health <= 0 then
                                    s.deathAnim = game.res.Animation:new(s)
                                    table.insert(game.dyingObjects, s)
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
        ::nextbot::
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
                                    player.score = (player.score or 0) + (s.max_health * 10)
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