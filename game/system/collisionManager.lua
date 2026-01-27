-- game/system/collisionManager.lua
local Collisions = require "game.system.physics"
local CollisionManager = {}

function CollisionManager.updateAll(game, dt, state)
    -- 1. Resolve Drones bumping into each other
    if state == "PLAYING" then
        Collisions.checkDroneCollisions(game.player.bullets, dt)
    end
    -- 2. Resolve Shapes bumping into each other
    Collisions.checkShapeCollisions(game.arena.shapes, dt)
    -- 3. Resolve Bullets/Drones hitting Shapes
    if state == "PLAYING" then
        Collisions.checkBulletShapeCollisions(game.player.bullets, game.arena.shapes, game, dt)
        -- 4. Resolve Player bumping into Shapes
        Collisions.checkPlayerShapeCollisions(game.player, game.arena.shapes, dt)
    end
end

return CollisionManager