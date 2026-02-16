-- game/entities/tank/bot.lua
-- AI-controlled tank: behaves like a player with leveling, upgrades, and wandering.

local Bot = {}
Bot.__index = Bot

local loader = require "game.utils.loader"
local Classes = require "game.data.classes"
local Physics = require "game.system.physics"

-- Upgrade paths by tier
local TIER_UPGRADES = {
    [15] = {2, 3, 4, 5}, -- MachineGun, Sniper, FlankGuard, Twin
    [30] = {6, 7, 8, 9, 10, 11, 12, 13, 25, 27}, -- Tier 3 classes
    [45] = {14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26} -- Tier 4 classes
}

-- Get class by ID
local function getClassById(id)
    for _, class in pairs(Classes) do
        if class.id == id then
            return class
        end
    end
    return nil
end

local function distSq(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    return dx * dx + dy * dy
end

-- Pick closest target: player, another bot, or a shape
local function pickTarget(self, arena)
    local maxRangeSq = 650 * 650
    local bestDistSq = maxRangeSq + 1
    local tx, ty = nil, nil
    local targetType = nil
    local targetObj = nil

    -- Player
    local player = arena.player
    if player and not player.isDead then
        local d2 = distSq(self.x, self.y, player.x, player.y)
        if d2 < bestDistSq then 
            bestDistSq = d2
            tx, ty = player.x, player.y
            targetType = "player"
            targetObj = player
        end
    end

    -- Other bots
    for _, other in ipairs(arena.bots) do
        if other ~= self and other.health > 0 then
            local d2 = distSq(self.x, self.y, other.x, other.y)
            if d2 < bestDistSq then 
                bestDistSq = d2
                tx, ty = other.x, other.y
                targetType = "bot"
                targetObj = other
            end
        end
    end

    -- Shapes (prioritize closer ones)
    for _, s in ipairs(arena.shapes) do
        if s.health and s.health > 0 then
            local d2 = distSq(self.x, self.y, s.x, s.y)
            if d2 < bestDistSq then 
                bestDistSq = d2
                tx, ty = s.x, s.y
                targetType = "shape"
                targetObj = s
            end
        end
    end

    return tx, ty, bestDistSq, targetType, targetObj
end

function Bot:new(x, y, arena)
    local self = setmetatable({}, Bot)
    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0
    self.radius = 25
    self.angle = 0
    self.isBot = true
    self.type = "bot"

    -- All bots are red (enemy color)
    self.color = {0.9, 0.25, 0.2}  -- Red
    self.outline_color = {0.63, 0.175, 0.14}  -- Darker red outline

    self.pushFactor = 2.0
    self.absorptionFactor = 1
    self.accel = 1500

    self.res = loader.loadAll()
    
    -- Start as basic Tank (level 1)
    self.tankData = Classes.Tank
    self.tankName = self.tankData.name
    self.classId = 1

    self.barrels = {}
    for _, b in ipairs(self.tankData.barrels) do
        table.insert(self.barrels, self.res.Barrel:new(self, b.delay, b.type, b))
    end
    self.addons = {}
    if self.tankData.addons then
        for _, addonConfig in ipairs(self.tankData.addons) do
            table.insert(self.addons, self.res.Turret:new(self, addonConfig))
        end
    end
    self.bullets = {}
    self.drones = {}

    self.fire_rate = self.tankData.fire_rate or 0.4
    self.fire_timer = 0

    self.max_health = 100
    self.health = 100
    self.healthBar = self.res.HealthBar:new(self.max_health)
    self.hitTimer = 0
    self.regen_speed = 2

    -- Leveling system (like player)
    self.level = 1
    self.maxLevel = 45
    self.xp = 0
    self.xpNextLevel = 100
    self.statPoints = 0
    self.score = 0

    self.stats = {
        movement_speed = 0,
        reload = 0,
        bullet_speed = 0,
        bullet_damage = 0,
        bullet_penetration = 0,
        max_health = 0,
        body_damage = 0,
        health_regen = 0
    }

    -- AI state
    self.targetAngle = 0
    self.aimSpeed = 3.0 -- radians per second (smooth aiming)
    self.attackRange = 500
    self.retreatHealthRatio = 0.35
    
        -- Wandering behavior - more natural/variable like real players
    self.wanderAngle = love.math.random() * math.pi * 2
    self.wanderChangeTimer = 0
    self.wanderChangeInterval = 2.0
    self.wanderSpeed = 0.6
    self.wanderPauseTimer = 0
    self.isWandering = true
    
    -- Human-like aiming with slight imprecision
    self.aimJitter = 0
    self.aimJitterTimer = 0
    
    -- Bot name for leaderboard
    local botNames = {"Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Ghost", "Hunter", 
                      "Ion", "Jester", "Kraken", "Lunar", "Maverick", "Nexus", "Omega", "Phantom",
                      "Quasar", "Rogue", "Spectre", "Titan", "Umbra", "Viper", "Warden", "Xenon", "Yeti", "Zenith"}
    self.name = botNames[love.math.random(1, #botNames)] .. "-" .. love.math.random(1, 99)

    return self
end

-- Auto-assign stat points randomly
local function autoAssignStatPoint(self)
    local statNames = {"movement_speed", "reload", "bullet_speed", "bullet_damage", 
                       "bullet_penetration", "max_health", "body_damage", "health_regen"}
    -- Prioritize certain stats based on tank type
    local priorities = {2, 2, 2, 2, 2, 2, 1, 1} -- Higher = more likely
    
    -- Weighted random selection
    local totalWeight = 0
    for _, w in ipairs(priorities) do
        totalWeight = totalWeight + w
    end
    
    local roll = love.math.random() * totalWeight
    local selectedStat = statNames[1]
    local cumulative = 0
    
    for i, stat in ipairs(statNames) do
        cumulative = cumulative + priorities[i]
        if roll <= cumulative then
            selectedStat = stat
            break
        end
    end
    
    -- Only assign if below max (8 points per stat)
    if self.stats[selectedStat] < 8 then
        self.stats[selectedStat] = self.stats[selectedStat] + 1
    else
        -- Find another stat
        for _, stat in ipairs(statNames) do
            if self.stats[stat] < 8 then
                self.stats[stat] = self.stats[stat] + 1
                break
            end
        end
    end
end

-- Upgrade to a new class
local function upgradeClass(self)
    local upgradeTier = TIER_UPGRADES[self.level]
    if not upgradeTier then return end
    
    -- Find available upgrades for this tier
    local availableUpgrades = {}
    for _, classId in ipairs(upgradeTier) do
        local class = getClassById(classId)
        if class and class.level <= self.level then
            -- Check if we already have a higher tier upgrade
            local shouldAdd = true
            -- Don't upgrade backwards
            if self.classId >= classId then
                shouldAdd = false
            end
            if shouldAdd then
                table.insert(availableUpgrades, class)
            end
        end
    end
    
    if #availableUpgrades > 0 then
        -- Pick a random upgrade
        local newClass = availableUpgrades[love.math.random(1, #availableUpgrades)]
        
        self.tankData = newClass
        self.tankName = newClass.name
        self.classId = newClass.id
        
        -- Rebuild barrels
        self.barrels = {}
        for _, b in ipairs(self.tankData.barrels) do
            table.insert(self.barrels, self.res.Barrel:new(self, b.delay, b.type, b))
        end
        
        -- Rebuild addons
        self.addons = {}
        if self.tankData.addons then
            for _, addonConfig in ipairs(self.tankData.addons) do
                table.insert(self.addons, self.res.Turret:new(self, addonConfig))
            end
        end
        
        self.fire_rate = self.tankData.fire_rate or 0.4
    end
end

function Bot:update(dt, arena, cam)
    -- Growth formula matching player (0.5 per level as you requested)
    self.radius = 25 + ((self.level - 1) * 0.5)
    self.accel = (25 + (2.5 * (self.stats.movement_speed + 1)) / (FRICTION * 30))

    -- LEVEL UP LOGIC (like player)
    if self.xp >= self.xpNextLevel and self.level < self.maxLevel then
        self.xp = self.xp - self.xpNextLevel
        self.level = self.level + 1
        self.xpNextLevel = math.floor(self.xpNextLevel * 1.2)
        self.statPoints = self.statPoints + 1
        
        -- Auto-assign stat point
        autoAssignStatPoint(self)
        
        -- Check for class upgrade at level thresholds
        if self.level == 15 or self.level == 30 or self.level == 45 then
            upgradeClass(self)
        end
    end

    local tx, ty, distSqTarget, targetType, targetObj = pickTarget(self, arena)
    local dist = math.sqrt(distSqTarget)
    local hasTarget = tx and ty

        -- WANDERING BEHAVIOR when no target (more natural, like real players)
    local moveDx, moveDy = 0, 0
    if not hasTarget then
        -- Handle pausing (real players don't move constantly)
        self.wanderPauseTimer = self.wanderPauseTimer - dt
        if self.wanderPauseTimer <= 0 then
            -- Randomly decide to pause or move
            if love.math.random() < 0.15 then
                -- Pause for 0.5-2 seconds
                self.wanderPauseTimer = 0.5 + love.math.random() * 1.5
                self.isWandering = false
            else
                -- Start/continue wandering
                self.isWandering = true
                self.wanderChangeTimer = 0 -- Force direction change
                self.wanderPauseTimer = love.math.random() * 3 + 1
            end
        end
        
        if self.isWandering then
            -- Update wander direction
            self.wanderChangeTimer = self.wanderChangeTimer - dt
            if self.wanderChangeTimer <= 0 then
                -- Pick new random direction with bias toward center and slight randomness
                local angleToCenter = math.atan2(arena.height/2 - self.y, arena.width/2 - self.x)
                local randomAngle = love.math.random() * math.pi * 2
                -- Occasionally move toward shapes to farm XP
                local nearestShape = nil
                local nearestShapeDist = 800 * 800
                for _, s in ipairs(arena.shapes) do
                    if s.health and s.health > 0 then
                        local d2 = distSq(self.x, self.y, s.x, s.y)
                        if d2 < nearestShapeDist then
                            nearestShapeDist = d2
                            nearestShape = s
                        end
                    end
                end
                
                if nearestShape and love.math.random() < 0.4 then
                    -- 40% chance to wander toward a nearby shape for farming
                    self.wanderAngle = math.atan2(nearestShape.y - self.y, nearestShape.x - self.x)
                else
                    -- Blend between random and toward center
                    local blend = 0.25 + love.math.random() * 0.15 -- 25-40% bias toward center
                    self.wanderAngle = angleToCenter * blend + randomAngle * (1 - blend)
                end
                
                -- Add some random variation to wander speed
                self.wanderSpeed = 0.4 + love.math.random() * 0.4 -- 40-80% speed
                self.wanderChangeTimer = 1.5 + love.math.random() * 2.5 -- Change every 1.5-4 seconds
            end
            
            -- Move in wander direction
            moveDx = math.cos(self.wanderAngle)
            moveDy = math.sin(self.wanderAngle)
            
            -- Smooth rotation toward wander direction
            local angleDiff = self.wanderAngle - self.angle
            while angleDiff > math.pi do angleDiff = angleDiff - math.pi * 2 end
            while angleDiff < -math.pi do angleDiff = angleDiff + math.pi * 2 end
            self.angle = self.angle + angleDiff * dt * (1.5 + love.math.random()) -- Variable rotation speed
            
            -- Apply acceleration at wander speed
            self.vx = self.vx + moveDx * self.accel * self.wanderSpeed
            self.vy = self.vy + moveDy * self.accel * self.wanderSpeed
        end
    else
        -- TARGET BEHAVIOR
        local dx = tx - self.x
        local dy = ty - self.y
        if dist < 1 then dist = 1 end
        local ux, uy = dx / dist, dy / dist

                -- SMOOTH AIMING with human-like characteristics
        local desiredAngle = math.atan2(dy, dx)
        
        -- Add slight "overshoot" and correction like real players
        self.aimJitterTimer = self.aimJitterTimer - dt
        if self.aimJitterTimer <= 0 then
            -- Update aim jitter (simulates hand movement imprecision)
            self.aimJitter = (love.math.random() - 0.5) * 0.15 -- +/- ~8 degrees max
            self.aimJitterTimer = 0.1 + love.math.random() * 0.2 -- Update every 100-300ms
        end
        
        -- Occasionally overshoot then correct (human reaction pattern)
        local overshootFactor = 1.0
        if love.math.random() < 0.05 then
            overshootFactor = 1.1 + love.math.random() * 0.2 -- 10-30% overshoot
        end
        
        local angleDiff = desiredAngle - self.angle + self.aimJitter
        -- Normalize angle to -pi to pi
        while angleDiff > math.pi do angleDiff = angleDiff - math.pi * 2 end
        while angleDiff < -math.pi do angleDiff = angleDiff + math.pi * 2 end
        
        -- Variable aim speed based on how far off we are (faster for big corrections)
        local aimSpeed = self.aimSpeed * (0.8 + math.abs(angleDiff) * 0.5) * overshootFactor
        self.angle = self.angle + angleDiff * math.min(1, aimSpeed * dt)

                -- TACTICAL MOVEMENT: approach or retreat based on health, distance, and target type
        if dist > 1 then
            local healthRatio = self.health / self.max_health
            local targetIsPlayer = targetType == "player"
            local targetIsBot = targetType == "bot"
            local targetLevel = targetObj and targetObj.level or 1
            local levelAdvantage = self.level - targetLevel
            
            -- More aggressive if higher level, more cautious if lower
            local aggressionFactor = 0.5 + (levelAdvantage / 45) * 0.5 -- 0.0 to 1.0
            aggressionFactor = math.max(0.2, math.min(0.9, aggressionFactor))
            
            if healthRatio < self.retreatHealthRatio then
                -- Low health: retreat more urgently
                moveDx, moveDy = -ux, -uy
                -- Add some strafe while retreating (real player behavior)
                local strafeDir = love.math.random() < 0.5 and 1 or -1
                moveDx = moveDx + (-uy * 0.5 * strafeDir)
                moveDy = moveDy + (ux * 0.5 * strafeDir)
            elseif dist < self.attackRange * 0.5 then
                -- Too close: back up while shooting
                local backOffWeight = 0.6 - (aggressionFactor * 0.3)
                local strafeWeight = 0.8
                moveDx = ux * (-backOffWeight) + (-uy * strafeWeight * (love.math.random() < 0.5 and 1 or -1))
                moveDy = uy * (-backOffWeight) + (ux * strafeWeight * (love.math.random() < 0.5 and 1 or -1))
            elseif dist < self.attackRange * 0.85 then
                -- Sweet spot: circle strafe and occasional stop-and-shoot
                if love.math.random() < 0.15 then
                    -- Stop briefly to shoot more accurately (15% chance)
                    moveDx, moveDy = 0, 0
                else
                    -- Circle strafe
                    local strafeDir = love.math.random() < 0.5 and 1 or -1
                    moveDx = -uy * (0.6 + aggressionFactor * 0.3) * strafeDir
                    moveDy = ux * (0.6 + aggressionFactor * 0.3) * strafeDir
                    -- Slight approach/retreat adjustment
                    moveDx = moveDx + ux * (aggressionFactor - 0.5) * 0.4
                    moveDy = moveDy + uy * (aggressionFactor - 0.5) * 0.4
                end
            elseif dist < self.attackRange then
                -- Approaching optimal range
                moveDx = ux * (0.5 + aggressionFactor * 0.4)
                moveDy = uy * (0.5 + aggressionFactor * 0.4)
                -- Add slight strafe
                local strafeDir = love.math.random() < 0.5 and 1 or -1
                moveDx = moveDx + (-uy * 0.3 * strafeDir)
                moveDy = moveDy + (ux * 0.3 * strafeDir)
            else
                -- Far range: approach with strafing
                moveDx = ux * (0.7 + aggressionFactor * 0.2)
                moveDy = uy * (0.7 + aggressionFactor * 0.2)
                -- Erratic strafing while approaching
                local strafeDir = love.math.random() < 0.5 and 1 or -1
                moveDx = moveDx + (-uy * 0.4 * strafeDir)
                moveDy = moveDy + (ux * 0.4 * strafeDir)
            end
            
            local len = math.sqrt(moveDx * moveDx + moveDy * moveDy)
            if len > 0 then
                moveDx, moveDy = moveDx / len, moveDy / len
                self.vx = self.vx + moveDx * self.accel
                self.vy = self.vy + moveDy * self.accel
            end
        end

        -- SHOOTING with stat-modified fire rate
        local inRange = dist < self.attackRange and dist > 40
        if inRange then
            -- Apply reload stat to fire rate (10% faster per point)
            local actualFireRate = self.fire_rate * (0.9 ^ self.stats.reload)
            
            self.fire_timer = self.fire_timer - dt
            if self.fire_timer <= 0 then
                self.fire_timer = actualFireRate
                for _, b in ipairs(self.barrels) do b.has_fired_this_cycle = false end
            end
            local progress = 1 - (self.fire_timer / actualFireRate)
            for _, barrel in ipairs(self.barrels) do
                if progress >= barrel.fire_delay and not barrel.has_fired_this_cycle then
                    local bullet = barrel:fire()
                    if bullet then
                        table.insert(self.bullets, bullet)
                        barrel.has_fired_this_cycle = true
                        local barrelAngle = self.angle + (barrel.angleOffset or 0)
                        local pushAngle = barrelAngle + math.pi
                        local recoilMult = barrel.config.recoilMult or 1.0
                        self.vx = self.vx + math.cos(pushAngle) * 150 * recoilMult
                        self.vy = self.vy + math.sin(pushAngle) * 150 * recoilMult
                    end
                end
            end
        else
            if self.fire_timer > 0 then self.fire_timer = self.fire_timer - dt
            else self.fire_timer = 0 end
        end
    end

    for _, addon in ipairs(self.addons) do
        addon:update(dt, arena, arena.shapes)
    end

    Physics.applyPhysics(self, dt)
    Physics.keepInArena(self, arena.width, arena.height)

    if self.health > 0 and self.health < self.max_health then
        local regenRate = self.regen_speed + self.stats.health_regen
        self.health = math.min(self.max_health, self.health + (regenRate * dt))
    end
    if self.hitTimer > 0 then self.hitTimer = self.hitTimer - dt end

    local maxAllowed = self.tankData.maxDrones or 8
    while #self.drones > maxAllowed do
        local oldest = table.remove(self.drones, 1)
        oldest.isdead = true
    end
    self.healthBar:update(dt, self.health, self.max_health)
end

-- Bots don't convert shapes
function Bot:convertShapeToDrone(_)
    return nil
end

function Bot:draw(alpha, style)
    local a = alpha or 1
    local r, g, b = self.color[1], self.color[2], self.color[3]
    local oR, oG, oB = self.outline_color[1], self.outline_color[2], self.outline_color[3]
    if style == "Old" then oR, oG, oB = 0.3, 0.3, 0.3 end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    for _, barrel in ipairs(self.barrels) do
        barrel:draw(a, love.timer.getDelta(), style)
    end

    if self.hitTimer > 0 then
        if self.hitTimer > 0.1 then
            r, g, b = 1, 1, 1
            if style == "New" then oR, oG, oB = 0.8, 0.8, 0.8 end
        else
            r, g, b = 1, 0.3, 0.3
            if style == "New" then oR, oG, oB = 0.8, 0.1, 0.1 end
        end
    end

    love.graphics.setColor(r, g, b, a)
    love.graphics.circle("fill", 0, 0, self.radius)
    love.graphics.setLineWidth(3)
    love.graphics.setColor(oR or 0, oG or 0, oB or 0, a)
    love.graphics.circle("line", 0, 0, self.radius)
    love.graphics.pop()

    for _, addon in ipairs(self.addons) do
        addon:draw(a, style)
    end
    self.healthBar:draw(self.x, self.y, self.radius, a)
    
    -- Draw nametag
    self:drawNametag(a)
end

function Bot:drawNametag(alpha)
    alpha = alpha or 1
    local font = love.graphics.getFont()
    local text = self.name .. " (Lvl " .. self.level .. ")"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    
    local x = self.x - textWidth / 2
    local y = self.y - self.radius - textHeight - 8
    
    -- Draw outline
    love.graphics.setColor(0, 0, 0, alpha)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.print(text, x + dx, y + dy)
            end
        end
    end
    
    -- Draw text
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(text, x, y)
    love.graphics.setColor(1, 1, 1, 1)
end

return Bot
