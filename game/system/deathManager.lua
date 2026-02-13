-- game/system/collisionManager.lua
local DeathManager = {}

function DeathManager.update(game, dt)
    -- 1. Handle Bullet/Drone Death
    -- Moves dead bullets to the dyingObjects list for their final animation
    for i = #game.player.bullets, 1, -1 do
        local b = game.player.bullets[i]
        if b.isdead then
            b.deathAnim = game.res.Animation:new(b)
            table.insert(game.dyingObjects, b)
            table.remove(game.player.bullets, i)
        end
    end

    -- 2. Handle Player Death
    if game.player.health <= 0 and not game.player.isDead then
        game.player.isDead = true
        game.player.deathAnim = game.res.Animation:new(game.player)
        table.insert(game.dyingObjects, game.player)
        print("Player has died!")
    end

    -- 2b. Handle Bot Bullet/Drone Death (with animation)
    for _, bot in ipairs(game.arena.bots) do
        for i = #bot.bullets, 1, -1 do
            local b = bot.bullets[i]
            if b.isdead then
                b.deathAnim = game.res.Animation:new(b)
                table.insert(game.dyingObjects, b)
                table.remove(bot.bullets, i)
            end
        end
    end

    -- 2c. Handle Bot Death
    for i = #game.arena.bots, 1, -1 do
        local bot = game.arena.bots[i]
        if bot.health <= 0 then
            bot.isDead = true
            bot.deathAnim = game.res.Animation:new(bot)
            table.insert(game.dyingObjects, bot)
            table.remove(game.arena.bots, i)
        end
    end

    -- 3. Process Dying Animations
    -- Updates the alpha/scale of "dying" objects and removes them when done
    for i = #game.dyingObjects, 1, -1 do
        local obj = game.dyingObjects[i]
        
        obj.deathAnim:update(dt)
        
        -- Optional: Let objects keep drifting/moving while they fade out
        if obj.update then
            obj:update(dt, game.arena, game.camera)
        end

        if obj.deathAnim.done then
            table.remove(game.dyingObjects, i)
        end
    end
end

return DeathManager