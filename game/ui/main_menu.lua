-- game/ui/main_menu.lua
local MainMenu = {}

local font = love.graphics.newFont("font.ttf", 14)
local titleFont = love.graphics.newFont("font.ttf", 72)
local subtitleFont = love.graphics.newFont("font.ttf", 22)

-- Helper to draw text with an outline
local function drawOutlinedText(text, x, y, width, align, textColor, outlineColor, useFont, outlineThickness)
    love.graphics.setFont(useFont or font)
    local outline = outlineColor or {0, 0, 0}
    local thickness = outlineThickness or 1
    love.graphics.setColor(outline)
    for dx = -thickness, thickness do
        for dy = -thickness, thickness do
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
    local modes = {
        { id = "FFA", label = "FFA" },
        { id = "Sandbox", label = "Sandbox" },
        { id = "TwoTeams", label = "2 Teams" },
    }
    
    -- Create Gamemode Toggles
    local gap = 14
    local mBtnW = 120
    local totalW = (mBtnW * #modes) + (gap * (#modes - 1))
    local modeStartX = (screenW / 2) - (totalW / 2)
    for i, mode in ipairs(modes) do
        local bx = modeStartX + (i - 1) * (mBtnW + gap)
        local by = screenH / 2 - 250
        
        buttons[mode.id .. "Btn"] = game.res.Button:new(mode.label, bx, by, mBtnW, btnH, function()
            game.gamemode = mode.id
            -- REFRESH UI: This re-runs this 'get' function via the UIManager
            game.ui.menus.MENU = MainMenu.get(game)
        end)

        -- Apply Selected/Idle Styles
        if game.gamemode == mode.id then
            buttons[mode.id .. "Btn"].color = {0.3, 0.7, 1.0}      -- Diep Blue
            buttons[mode.id .. "Btn"].hoverColor = {0.4, 0.8, 1.0}
        else
            buttons[mode.id .. "Btn"].color = {0.4, 0.4, 0.4}      -- Gray
            buttons[mode.id .. "Btn"].hoverColor = {0.5, 0.5, 0.5}
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
    drawOutlinedText("Select Gamemode:", 0, h/2 - 300, w, "center", {0.85, 0.85, 0.85}, {0,0,0}, subtitleFont, 2)
    drawOutlinedText("DIEP.IO", 0, h/2 - 185, w, "center", {1,1,1}, {0,0,0}, titleFont, 3)
    -- Reset so button centering logic (which reads current font height) remains correct.
    love.graphics.setFont(font)
end

return MainMenu