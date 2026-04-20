-- game/system/entityManager.lua
-- Holds all registered entities plus typed views (Native/Manager.ts pattern).

local ObjectEntity = require "game.native.objectEntity"
local LivingEntity = require "game.native.livingEntity"

local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager.new()
    return setmetatable({
        entities = {},
        objects = {},
        living = {},
    }, EntityManager)
end

function EntityManager:add(entity)
    table.insert(self.entities, entity)
    if ObjectEntity.isObject(entity) then
        table.insert(self.objects, entity)
    end
    if LivingEntity.isLive(entity) then
        table.insert(self.living, entity)
    end
end

local function removeFrom(list, entity)
    for i = #list, 1, -1 do
        if list[i] == entity then
            table.remove(list, i)
        end
    end
end

function EntityManager:remove(entity)
    removeFrom(self.entities, entity)
    removeFrom(self.objects, entity)
    removeFrom(self.living, entity)
end

function EntityManager:clear()
    self.entities = {}
    self.objects = {}
    self.living = {}
end

--- Remove a shape from arena.shapes and from this manager (single place for dual bookkeeping).
function EntityManager.removeShapeFromWorld(game, shape)
    if game.arena and game.arena.shapes then
        for idx = #game.arena.shapes, 1, -1 do
            if game.arena.shapes[idx] == shape then
                table.remove(game.arena.shapes, idx)
            end
        end
    end
    if game.arena and game.arena.entityManager then
        game.arena.entityManager:remove(shape)
    end
end

return EntityManager
