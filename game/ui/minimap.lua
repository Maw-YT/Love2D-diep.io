-- game/ui/minimap.lua
local Minimap = {}

function Minimap.draw(game, player)
    local arena = game.arena
    if not arena then return end

    local mapSize, padding = 150, 20
    local screenW, screenH = love.graphics.getDimensions()
    local mx, my = screenW - mapSize - padding, screenH - mapSize - padding

    -- Background & Border
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", mx, my, mapSize, mapSize)
    love.graphics.setColor(0.33, 0.33, 0.33, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", mx, my, mapSize, mapSize)

    local scaleX, scaleY = mapSize / arena.width, mapSize / arena.height

    -- Nest (Center Area)
    local nestSize = arena.width * 0.15
    love.graphics.setColor(0.5, 0.5, 0.9, 0.2)
    love.graphics.rectangle("fill", 
        mx + (arena.width / 2 - nestSize / 2) * scaleX,
        my + (arena.height / 2 - nestSize / 2) * scaleY,
        nestSize * scaleX, nestSize * scaleY)

    -- Player Dot
    if player then
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", mx + (player.x * scaleX), my + (player.y * scaleY), 3)
    end
    love.graphics.setLineWidth(1)
end

return Minimap