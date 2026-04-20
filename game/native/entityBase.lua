-- game/native/entityBase.lua
-- Shared entity base object with common state and helpers.

local ObjectEntity = require "game.native.objectEntity"
local LivingEntity = require "game.native.livingEntity"

local EntityBase = {}
EntityBase.__index = EntityBase

local nextEntityId = 0

local function makeId(prefix)
    nextEntityId = nextEntityId + 1
    return string.format("%s_%d", prefix or "entity", nextEntityId)
end

function EntityBase:new(config)
    config = config or {}

    local self = setmetatable({}, EntityBase)
    self.id = config.id or makeId(config.type)
    self.type = config.type or "entity"
    self.name = config.name

    self.x = config.x or 0
    self.y = config.y or 0
    self.vx = config.vx or 0
    self.vy = config.vy or 0

    self.angle = config.angle or 0
    self.radius = config.radius or 20

    self.pushFactor = config.pushFactor or 1
    self.absorptionFactor = config.absorptionFactor or 1
    self.styleOpacity = config.styleOpacity or 1

    self.isDead = false
    self.isdead = false -- Legacy compatibility with older systems.
    self.isActive = true

    if config.attach == "living" then
        self.max_health = config.max_health or config.maxHealth or 100
        self.health = config.health or self.max_health
        LivingEntity.attach(self)
    else
        ObjectEntity.attach(self)
    end

    if config.team ~= nil then
        self:setTeam(config.team)
    end
    if config.owner ~= nil then
        self:setOwner(config.owner)
    end

    return self
end

function EntityBase:getPosition()
    return self.x, self.y
end

function EntityBase:setPosition(x, y)
    self.x = x or self.x
    self.y = y or self.y
end

function EntityBase:getVelocity()
    return self.vx, self.vy
end

function EntityBase:setVelocity(vx, vy)
    self.vx = vx or self.vx
    self.vy = vy or self.vy
end

function EntityBase:getRadius()
    return self.radius
end

function EntityBase:setActive(active)
    self.isActive = active ~= false
end

function EntityBase:setTeam(team)
    self.team = team
    if self.relationsData and self.relationsData.values then
        self.relationsData.values.team = team
    end
end

function EntityBase:setOwner(owner)
    self.owner = owner
    if self.relationsData and self.relationsData.values then
        self.relationsData.values.owner = owner
    end
end

function EntityBase:isAlive()
    return not self.isDead
end

function EntityBase:setDead(dead)
    local value = dead == true
    self.isDead = value
    self.isdead = value
    if value then
        self.isActive = false
    end
end

function EntityBase:destroy()
    self:setDead(true)
end

-- Overridable hooks for child entities.
function EntityBase:update(_, _)
end

function EntityBase:draw(_, _)
end

return EntityBase
