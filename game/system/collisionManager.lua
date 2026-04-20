-- game/system/collisionManager.lua
local Collisions = require "game.system.physics"
local CollisionManager = {}

local function collectLiving(game)
    if game.arena and game.arena.entityManager and game.arena.entityManager.living then
        local snapshot = {}
        for i = 1, #game.arena.entityManager.living do
            snapshot[i] = game.arena.entityManager.living[i]
        end
        return snapshot
    end
    return {}
end

local function collectObjects(game)
    local objects = {}
    for _, bullet in ipairs(game.player.bullets) do
        table.insert(objects, bullet)
    end
    for _, bot in ipairs(game.arena.bots) do
        for _, bullet in ipairs(bot.bullets) do
            table.insert(objects, bullet)
        end
    end
    for _, boss in ipairs(game.arena.bosses) do
        for _, bullet in ipairs(boss.bullets) do
            table.insert(objects, bullet)
        end
    end
    return objects
end

function CollisionManager.updateAll(game, dt, state)
    local living = collectLiving(game)
    Collisions.resolveLivingVsLiving(living, game, dt)
    if state == "PLAYING" then
        local objects = collectObjects(game)
        Collisions.resolveObjectVsObject(objects, dt)
        Collisions.resolveLivingVsObject(living, objects, game, dt)
    end
end

return CollisionManager