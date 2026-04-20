local EntityBase = require "game.native.entityBase"
local Boss = setmetatable({}, { __index = EntityBase })
Boss.__index = Boss

local Physics = require "game.system.physics"
local DeathManager = require "game.system.deathManager"
local loader = require "game.utils.loader"

function Boss:new(x, y)
    local self = EntityBase:new({
        type = "boss",
        attach = "living",
        team = "natural",
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        radius = 90,
        angle = 0,
        max_health = 5000,
        health = 5000,
    })
    setmetatable(self, Boss)

    self.name = "Summoner"
    self.color = {0.85, 0.25, 0.85}
    self.outline_color = {0.55, 0.12, 0.55}
    self.pushFactor = 6.5
    self.absorptionFactor = 3.0
    self.speed = 30
    self.hitTimer = 0
    self.wanderAngle = love.math.random() * math.pi * 2
    self.wanderChangeTimer = 0
    self.spinSpeed = 1.8
    self.fire_rate = 1.0
    self.fire_timer = 0
    self.maxSummons = 16

    self.stats = {
        movement_speed = 0,
        reload = 0,
        bullet_speed = 0,
        bullet_damage = 0,
        bullet_penetration = 0,
        max_health = 0,
        body_damage = 0,
        health_regen = 0,
    }
    self.tankData = { droneType = "square" }
    self.res = loader.loadAll()
    self.healthBar = self.res.HealthBar:new(self.max_health)
    self.bullets = {}
    self.drones = self.bullets

    self.barrels = {}
    local configs = {
        { angleOffset = 0, yOffsetMult = 0.3, lengthMult = 1.2, widthMult = 0.6, type = "drone", bulletSize = 1.2, spread = 0.0 },
        { angleOffset = math.pi / 2, yOffsetMult = 0.3, lengthMult = 1.2, widthMult = 0.6, type = "drone", bulletSize = 1.2, spread = 0.0 },
        { angleOffset = math.pi, yOffsetMult = 0.3, lengthMult = 1.2, widthMult = 0.6, type = "drone", bulletSize = 1.2, spread = 0.0 },
        { angleOffset = -math.pi / 2, yOffsetMult = 0.3, lengthMult = 1.2, widthMult = 0.6, type = "drone", bulletSize = 1.2, spread = 0.0 },
    }
    for _, cfg in ipairs(configs) do
        table.insert(self.barrels, self.res.Barrel:new(self, 0, "drone", cfg, self))
    end

    return self
end

function Boss:update(dt, arena)
    -- Summoner should roam around, not directly chase targets.
    self.wanderChangeTimer = self.wanderChangeTimer - dt
    if self.wanderChangeTimer <= 0 then
        self.wanderChangeTimer = 1.0 + love.math.random() * 2.2
        self.wanderAngle = love.math.random() * math.pi * 2
    end
    self.vx = self.vx + math.cos(self.wanderAngle) * self.speed
    self.vy = self.vy + math.sin(self.wanderAngle) * self.speed

    -- Constant 360 pressure: rotate body/barrels continuously.
    self.angle = self.angle + (self.spinSpeed * dt)

    self.fire_timer = self.fire_timer - dt
    if self.fire_timer <= 0 then
        self.fire_timer = self.fire_rate
        for _, barrel in ipairs(self.barrels) do
            local summon = barrel:fire()
            if summon then
                summon.droneType = "square"
                summon.radius = math.max(12, self.radius * 0.28)
                summon.damage = 8
                summon.penetration = 8
                summon.lifetime = 18.0
                summon.speed = 280
                summon.turnSpeed = 9
                -- Barrel:fire() already inserts drones into player.drones (= self.bullets for this boss).
            end
        end
    end

    while #self.bullets > self.maxSummons do
        local oldest = table.remove(self.bullets, 1)
        if oldest then
            if oldest.setDead then
                oldest:setDead(true)
            else
                oldest.isDead = true
                oldest.isdead = true
            end
            DeathManager.queueDyingProjectile(arena.game, oldest)
        end
    end

    Physics.applyPhysics(self, dt)
    Physics.keepInArena(self, arena.width, arena.height)

    if self.hitTimer > 0 then
        self.hitTimer = self.hitTimer - dt
    end
    self.healthBar:update(dt, self.health, self.max_health)
end

function Boss:draw(alpha, style)
    local a = alpha or 1
    local r, g, b = self.color[1], self.color[2], self.color[3]
    local oR, oG, oB = self.outline_color[1], self.outline_color[2], self.outline_color[3]

    if self.hitTimer > 0 then
        if self.hitTimer > 0.1 then
            r, g, b = 1, 1, 1
            oR, oG, oB = 0.8, 0.8, 0.8
        else
            r, g, b = 1, 0.3, 0.3
            oR, oG, oB = 0.8, 0.1, 0.1
        end
    elseif style == "Old" then
        oR, oG, oB = 0.3, 0.3, 0.3
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    for _, barrel in ipairs(self.barrels) do
        barrel:draw(a, love.timer.getDelta(), style)
    end

    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", -self.radius, -self.radius, self.radius * 2, self.radius * 2)

    love.graphics.setLineWidth(5)
    love.graphics.setColor(oR, oG, oB, a)
    love.graphics.rectangle("line", -self.radius, -self.radius, self.radius * 2, self.radius * 2)

    love.graphics.setLineWidth(1)
    love.graphics.pop()

    if self.healthBar then
        self.healthBar:draw(self.x, self.y, self.radius, a)
    end
end

return Boss
