-- game/native/livingEntity.lua
-- Living tier: object + health (Entity/Live.ts).

local FieldGroups = require "game.native.fieldGroups"
local ObjectEntity = require "game.native.objectEntity"

local LivingEntity = {}

function LivingEntity.isLive(e)
    return ObjectEntity.isObject(e) and e.healthData ~= nil
end

function LivingEntity.attach(entity)
    ObjectEntity.attach(entity)
    FieldGroups.attachHealthGroup(entity)
end

return LivingEntity
