-- game/system/collisionManager.lua
local Collisions = require "game.system.collisions"
local CollisionManager = {}

function CollisionManager.updateAll(game, dt)
    -- 1. Resolve Drones bumping into each other
    Collisions.checkDroneCollisions(game.player.bullets, dt)
    -- 2. Resolve Shapes bumping into each other
    Collisions.checkShapeCollisions(game.arena.shapes, dt)
    -- 3. Resolve Bullets/Drones hitting Shapes
    Collisions.checkBulletShapeCollisions(game.player.bullets, game.arena.shapes, game, dt)
    -- 4. Resolve Player bumping into Shapes
    Collisions.checkPlayerShapeCollisions(game.player, game.arena.shapes, dt)
end

return CollisionManager