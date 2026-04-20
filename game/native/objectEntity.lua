-- game/native/objectEntity.lua
-- Object tier: position, physics, relations, style (Entity/Object.ts).

local FieldGroups = require "game.native.fieldGroups"

local ObjectEntity = {}

function ObjectEntity.isObject(e)
    return type(e) == "table" and e.positionData ~= nil and e.physicsData ~= nil
end

function ObjectEntity.attach(entity)
    FieldGroups.attachPositionGroup(entity)
    FieldGroups.attachPhysicsGroup(entity)
    FieldGroups.attachRelationsGroup(entity)
    FieldGroups.attachStyleGroup(entity)
end

return ObjectEntity
