-- main.lua
love.filesystem.setIdentity("diep-love")

function love.load()
    require "game.init"
    Game:load()
end

function love.update(dt)
    Game:update(dt)
end

function love.draw()
    Game:draw()
end

function love.keypressed(key)
    if key == "escape" then
        if Game.state == "PLAYING" then
            Game.state = "PAUSED"
        elseif Game.state == "PAUSED" then
            Game.state = "PLAYING"
        end
    end
    if key == "f11" then
        local isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen)
    end
end

function love.mousepressed(x, y, button)
    -- Tell the UI manager that a click happened
    if Game.ui then
        Game.ui:mousepressed(x, y, button)
    end
end