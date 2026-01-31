-- game/ui/main_menu.lua
local MainMenu = {}

local font = love.graphics.newFont("font.ttf", 14)

local function drawOutlinedText(text, x, y, width, align, textColor, outlineColor)
    love.graphics.setFont(font)
    local outline = outlineColor or {0, 0, 0} -- Default to black
    
    love.graphics.setColor(outline)
    -- Draw the text shifted in 8 directions to create the outline
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.printf(text, x + dx, y + dy, width, align)
            end
        end
    end
    
    -- Draw the main text on top
    love.graphics.setColor(textColor)
    love.graphics.printf(text, x, y, width, align)
end

function MainMenu.get(game)
    local screenW, screenH = love.graphics.getDimensions()
    local btnW, btnH = 200, 50
    local centerX = screenW / 2 - btnW / 2

    return {
        playButton = game.res.Button:new("PLAY", centerX, screenH / 2 - 30, btnW, btnH, function() 
            game:startGame() 
        end),
        optionsButton = game.res.Button:new("OPTIONS", centerX, screenH / 2 + 30, btnW, btnH, function()
            game.state = "OPTIONS"
        end)
    }
end

function MainMenu.drawOverlay()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1)
    drawOutlinedText("DIEP.IO (Love2D Edition)", 0, h/2 - 120, w, "center", {1,1,1}, {0,0,0})
    drawOutlinedText("Created by Maw", 0, h/2 + 200, w, "center", {1,1,1}, {0,0,0})
end

return MainMenu