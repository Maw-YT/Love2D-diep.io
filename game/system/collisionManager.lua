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
        -- 3. Resolve Bullets/Drones hitting Shapes (player + bot bullets)
        Collisions.checkBulletShapeCollisions(game.player.bullets, game.arena.shapes, game, dt, ShapeGrid, CellSize)
        for _, bot in ipairs(game.arena.bots) do
            Collisions.checkDroneCollisions(bot.bullets, dt)
            Collisions.checkBulletShapeCollisions(bot.bullets, game.arena.shapes, game, dt, ShapeGrid, CellSize)
        end
        -- 4. Resolve Player and Bots bumping into Shapes
        Collisions.checkPlayerShapeCollisions(game.player, game.arena.shapes, game, dt, ShapeGrid, CellSize)
        Collisions.checkBotShapeCollisions(game.arena.bots, game.arena.shapes, game, dt, ShapeGrid, CellSize)
        -- 5. Player bullets vs Bots, Bot bullets vs Player, Bot bullets vs Bots, bodies
        Collisions.checkPlayerBulletBotCollisions(game.player.bullets, game.arena.bots, game, dt)
        Collisions.checkBotBulletPlayerCollisions(game.arena.bots, game.player, game, dt)
        Collisions.checkBotBulletBotCollisions(game.arena.bots, game, dt)
        Collisions.checkBotBotCollisions(game.arena.bots, game, dt)
        Collisions.checkPlayerBotCollisions(game.player, game.arena.bots, game, dt)
    end
end

return CollisionManager