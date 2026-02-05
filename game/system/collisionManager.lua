-- game/system/collisionManager.lua
local Collisions = require "game.system.physics"
local CollisionManager = {}

function CollisionManager.updateAll(game, dt, state)
    local CellSize = 100
    local ShapeGrid = Collisions.newGrid(game.arena.shapes, CellSize)
    -- 1. Resolve Shapes bumping into each other
    Collisions.checkShapeCollisionsOptimized(ShapeGrid, CellSize, dt)
    if state == "PLAYING" then
        -- 2. Resolve Drones bumping into each other
        Collisions.checkDroneCollisions(game.player.bullets, dt)
        -- 3. Resolve Bullets/Drones hitting Shapes
        Collisions.checkBulletShapeCollisions(game.player.bullets, game.arena.shapes, game, dt, ShapeGrid, CellSize)
        -- 4. Resolve Player bumping into Shapes
        Collisions.checkPlayerShapeCollisions(game.player, game.arena.shapes, game, dt, ShapeGrid, CellSize)
    end
end

return CollisionManager