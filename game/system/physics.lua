-- game/system/physics.lua
local EntityManagerMod = require "game.system.entityManager"
local ObjectEntity = require "game.native.objectEntity"
local LivingEntity = require "game.native.livingEntity"

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

-- 3. Core Knockback Logic
local function applyKnockback(objA, objB, dt)
    local dx, dy = objA.x - objB.x, objA.y - objB.y
    local dist = math.sqrt(dx*dx + dy*dy)
    local min = (objA.radius or 20) + (objB.radius or 20)

    -- THE FIX: Hard-push them apart so they aren't "inside" each other
    if dist < min then
        local overlap = min - dist
        local nx, ny = dx/dist, dy/dist -- Normal vector
        -- Gently nudge them apart by half the overlap each
        objA.x = objA.x + nx * overlap * 0.05
        objA.y = objA.y + ny * overlap * 0.05
        -- Note: Do the opposite for objB if it's also a moving entity
    end

    -- Now apply the "Diep" style velocity knockback
    local angle = math.atan2(dy, dx)
    local kbMagnitude = (objA.absorptionFactor or 1) * (objB.pushFactor or 1) * 500 * dt
    objA.vx = objA.vx + math.cos(angle) * kbMagnitude
    objA.vy = objA.vy + math.sin(angle) * kbMagnitude
end

--- COLLISION HANDLERS ---
local function isDead(entity)
    if not entity then return true end
    return entity.isDead == true or entity.isdead == true
end

local function setDead(entity)
    if not entity then return end
    if entity.setDead then
        entity:setDead(true)
    else
        entity.isDead = true
        entity.isdead = true
    end
end

local function radiusOf(entity)
    if entity.getRadius then return entity:getRadius() end
    return entity.radius or entity.size or 20
end

local function teamOf(entity)
    if entity.relationsData and entity.relationsData.values then
        return entity.relationsData.values.team
    end
    return entity.team
end

local function ownerOf(entity)
    if entity.relationsData and entity.relationsData.values then
        return entity.relationsData.values.owner
    end
    return entity.owner or entity.player
end

local function sameTeamOrOwner(a, b)
    if a == b then return true end
    local ownerA, ownerB = ownerOf(a), ownerOf(b)
    if ownerA and ownerA == b then return true end
    if ownerB and ownerB == a then return true end
    if ownerA and ownerB and ownerA == ownerB then return true end
    local teamA, teamB = teamOf(a), teamOf(b)
    if teamA ~= nil and teamB ~= nil and teamA == teamB then return true end
    return false
end

local function overlaps(a, b)
    local dx, dy = b.x - a.x, b.y - a.y
    local min = radiusOf(a) + radiusOf(b)
    return (dx * dx + dy * dy) < (min * min)
end

local HASH_CELL_SIZE = 140

local function hashKey(gx, gy)
    return gx .. ":" .. gy
end

local function addToHash(hash, entity, cellSize)
    local r = radiusOf(entity)
    local minX = math.floor((entity.x - r) / cellSize)
    local maxX = math.floor((entity.x + r) / cellSize)
    local minY = math.floor((entity.y - r) / cellSize)
    local maxY = math.floor((entity.y + r) / cellSize)

    for gx = minX, maxX do
        for gy = minY, maxY do
            local key = hashKey(gx, gy)
            local bucket = hash[key]
            if not bucket then
                bucket = {}
                hash[key] = bucket
            end
            bucket[#bucket + 1] = entity
        end
    end
end

local function buildSpatialHash(entities, predicate, cellSize)
    local hash = {}
    for i = 1, #entities do
        local entity = entities[i]
        if predicate(entity) then
            addToHash(hash, entity, cellSize)
        end
    end
    return hash
end

local function forNearbyCandidates(entity, hash, cellSize, callback)
    local r = radiusOf(entity)
    local minX = math.floor((entity.x - r) / cellSize)
    local maxX = math.floor((entity.x + r) / cellSize)
    local minY = math.floor((entity.y - r) / cellSize)
    local maxY = math.floor((entity.y + r) / cellSize)

    for gx = minX, maxX do
        for gy = minY, maxY do
            local bucket = hash[hashKey(gx, gy)]
            if bucket then
                for i = 1, #bucket do
                    callback(bucket[i])
                end
            end
        end
    end
end

local function attackerFrom(entity)
    return entity and (entity.player or ownerOf(entity)) or nil
end

local function rewardXp(attacker, amount)
    if not attacker or attacker.xp == nil then return end
    attacker.xp = attacker.xp + amount
    attacker.score = (attacker.score or 0) + amount
end

local function killLiving(game, living, attacker)
    if isDead(living) then return end
    setDead(living)

    if living.type == "shape" then
        rewardXp(attacker, (living.max_health or 0) * 10)
        local converted = false
        if attacker and attacker.convertShapeToDrone then
            converted = attacker:convertShapeToDrone(living) ~= nil
        end
        if not converted then
            living.deathAnim = game.res.Animation:new(living)
            table.insert(game.dyingObjects, living)
        end
        EntityManagerMod.removeShapeFromWorld(game, living)
        return
    end

    rewardXp(attacker, (living.max_health or 100) * 12)

    if game.notificationSystem then
        if attacker == game.player and living.name then
            game.notificationSystem:notifyKilled(living.name)
        elseif living == game.player and attacker and attacker.name then
            game.notificationSystem:notifyKilledBy(attacker.name)
        end
    end
end

local function canDamageLiving(living, obj)
    if not obj.damage then return false end
    if sameTeamOrOwner(living, obj) then return false end
    if living == obj then return false end
    return true
end

-- Generic collision pass: LivingEntity vs ObjectEntity.
function Physics.resolveLivingVsObject(livingList, objectList, game, dt)
    local objectHash = buildSpatialHash(objectList, function(obj)
        return obj ~= nil
            and ObjectEntity.isObject(obj)
            and not LivingEntity.isLive(obj)
            and not isDead(obj)
    end, HASH_CELL_SIZE)

    for i = 1, #livingList do
        local living = livingList[i]
        if LivingEntity.isLive(living) and not isDead(living) then
            local seen = {}
            local stop = false
            forNearbyCandidates(living, objectHash, HASH_CELL_SIZE, function(obj)
                if stop then return end
                if seen[obj] then return end
                seen[obj] = true

                if overlaps(living, obj) then
                    applyKnockback(living, obj, dt)
                    applyKnockback(obj, living, dt)

                    if canDamageLiving(living, obj) then
                        living.health = living.health - obj.damage
                        living.hitTimer = 0.2

                        if obj.penetration ~= nil then
                            obj.penetration = obj.penetration - 1
                            if obj.penetration <= 0 then setDead(obj) end
                        end

                        if living.health <= 0 then
                            killLiving(game, living, attackerFrom(obj))
                            stop = true
                        end
                    end
                end
            end)
        end
    end
end

-- Generic collision pass: ObjectEntity vs ObjectEntity.
-- Used for projectile-to-projectile interactions without type-specific checks.
function Physics.resolveObjectVsObject(objectList, dt)
    local objectHash = buildSpatialHash(objectList, function(obj)
        return obj ~= nil
            and ObjectEntity.isObject(obj)
            and not LivingEntity.isLive(obj)
            and not isDead(obj)
    end, HASH_CELL_SIZE)

    local objectIndex = {}
    for i = 1, #objectList do
        objectIndex[objectList[i]] = i
    end

    for i = 1, #objectList do
        local a = objectList[i]
        if ObjectEntity.isObject(a) and not LivingEntity.isLive(a) and not isDead(a) then
            local seen = {}
            forNearbyCandidates(a, objectHash, HASH_CELL_SIZE, function(b)
                if seen[b] then return end
                seen[b] = true
                local j = objectIndex[b]
                if not j or j <= i then return end
                if isDead(b) then return end
                if not overlaps(a, b) then return end

                applyKnockback(a, b, dt)
                applyKnockback(b, a, dt)

                -- Optional penetration trade on impact (generic object property).
                if a.penetration ~= nil and b.penetration ~= nil and not sameTeamOrOwner(a, b) then
                    a.penetration = a.penetration - 1
                    b.penetration = b.penetration - 1
                    if a.penetration <= 0 then setDead(a) end
                    if b.penetration <= 0 then setDead(b) end
                end
            end)
        end
    end
end

local function bodyDamageFrom(attacker)
    local stats = attacker.stats or {}
    local bodyStat = stats.body_damage or 0
    return 0.5 + (bodyStat * 0.5)
end

local function selfCollisionDamage(defender)
    local stats = defender.stats or {}
    local bodyStat = stats.body_damage or 0
    return 0.5 * (1 - (bodyStat * 0.1))
end

-- Generic collision pass: LivingEntity vs LivingEntity.
function Physics.resolveLivingVsLiving(livingList, game, dt)
    local livingHash = buildSpatialHash(livingList, function(e)
        return LivingEntity.isLive(e) and not isDead(e)
    end, HASH_CELL_SIZE)

    local livingIndex = {}
    for i = 1, #livingList do
        livingIndex[livingList[i]] = i
    end

    for i = 1, #livingList do
        local a = livingList[i]
        if LivingEntity.isLive(a) and not isDead(a) then
            local seen = {}
            forNearbyCandidates(a, livingHash, HASH_CELL_SIZE, function(b)
                if seen[b] then return end
                seen[b] = true
                local j = livingIndex[b]
                if not j or j <= i then return end
                if overlaps(a, b) then
                    applyKnockback(a, b, dt)
                    applyKnockback(b, a, dt)

                    -- Same-team/owner entities still collide, but cannot hurt each other.
                    if sameTeamOrOwner(a, b) then
                        return
                    end

                    -- Keep original spawn-protection behavior for player body damage.
                    local aCanDeal = not (a == game.player and (a.lifeTime or 0) <= 3)
                    local bCanDeal = not (b == game.player and (b.lifeTime or 0) <= 3)

                    local damageToB = aCanDeal and bodyDamageFrom(a) or 0
                    local damageToA = bCanDeal and bodyDamageFrom(b) or 0

                    if damageToA > 0 then
                        -- Tanks retain their old reduced self-damage profile.
                        if a.stats then
                            damageToA = selfCollisionDamage(a)
                        end
                        a.health = a.health - damageToA
                    end

                    if damageToB > 0 then
                        if b.stats then
                            damageToB = selfCollisionDamage(b)
                        end
                        b.health = b.health - damageToB
                    end

                    a.hitTimer = 0.2
                    b.hitTimer = 0.2

                    if a.health <= 0 then killLiving(game, a, b) end
                    if b.health <= 0 then killLiving(game, b, a) end
                end
            end)
        end
    end
end

return Physics