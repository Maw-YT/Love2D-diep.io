-- game/ui/main_menu.lua
local MainMenu = {}

local font = love.graphics.newFont("font.ttf", 14)

-- Helper to draw text with an outline
local function drawOutlinedText(text, x, y, width, align, textColor, outlineColor)
    love.graphics.setFont(font)
    local outline = outlineColor or {0, 0, 0}
    love.graphics.setColor(outline)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.printf(text, x + dx, y + dy, width, align)
            end
        end
    end
    love.graphics.setColor(textColor)
    love.graphics.printf(text, x, y, width, align)
end

function MainMenu.get(game)
    local screenW, screenH = love.graphics.getDimensions()
    local btnW, btnH = 200, 50
    local centerX = screenW / 2 - btnW / 2
    
    -- Ensure a default gamemode is set
    game.gamemode = game.gamemode or "FFA"
    
    local buttons = {}
    local modes = {"FFA", "Sandbox"}
    
    -- Create Gamemode Toggles
    for i, modeName in ipairs(modes) do
        local mBtnW = (btnW / 2) - 5
        local bx = centerX + (i - 1) * (mBtnW + 10)
        local by = screenH / 2 - 90
        
        buttons[modeName .. "Btn"] = game.res.Button:new(modeName, bx, by, mBtnW, btnH, function()
            game.gamemode = modeName
            -- REFRESH UI: This re-runs this 'get' function via the UIManager
            game.ui.menus.MENU = MainMenu.get(game)
        end)

        -- Apply Selected/Idle Styles
        if game.gamemode == modeName then
            buttons[modeName .. "Btn"].color = {0.3, 0.7, 1.0}      -- Diep Blue
            buttons[modeName .. "Btn"].hoverColor = {0.4, 0.8, 1.0}
        else
            buttons[modeName .. "Btn"].color = {0.4, 0.4, 0.4}      -- Gray
            buttons[modeName .. "Btn"].hoverColor = {0.5, 0.5, 0.5}
        end
    end

    -- Main Navigation
    buttons.playButton = game.res.Button:new("PLAY", centerX, screenH / 2 - 30, btnW, btnH, function() 
        game:startGame() 
    end)
    
    buttons.optionsButton = game.res.Button:new("OPTIONS", centerX, screenH / 2 + 30, btnW, btnH, function()
        game.state = "OPTIONS"
    end)
    
    return buttons
end

function MainMenu.drawOverlay()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1)
    drawOutlinedText("DIEP.IO", 0, h/2 - 160, w, "center", {1,1,1}, {0,0,0})
    drawOutlinedText("Select Gamemode:", 0, h/2 - 115, w, "center", {0.8, 0.8, 0.8}, {0,0,0})
end

return MainMenu