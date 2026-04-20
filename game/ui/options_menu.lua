-- game/ui/options_menu.lua
local OptionsMenu = {}

-- Initialize font
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

function OptionsMenu.get(game)
    local screenW, screenH = love.graphics.getDimensions()
    return {
        backButton = game.res.Button:new("BACK", screenW / 2 - 100, screenH - 100, 200, 50, function()
            game.state = "MENU"
        end)
    }
end

function OptionsMenu.draw(game)
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Header and label with outlined text
    drawOutlinedText("SETTINGS", 0, 100, w, "center", {1, 1, 1})
    drawOutlinedText("Style:", w/2 - 150, 205, 100, "left", {1, 1, 1})
    
    local styles = {"New", "Old"}
    for i, s in ipairs(styles) do
        local bx, by = w/2 - 50 + (i-1) * 110, 200
        
        -- Set base color based on selection
        local baseColor = {0.3, 0.3, 0.3}
        if game.style == s then
            baseColor = {0, 0.7, 1}
        end
        
        -- 1. Draw the dark outline/border for the box
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", bx - 2, by - 2, 100 + 4, 30 + 4, 4)
        
        -- 2. Draw the main selection box
        love.graphics.setColor(baseColor)
        love.graphics.rectangle("fill", bx, by, 100, 30, 4)
        
        -- 3. Draw the "Diep" shadow inside the box
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("fill", bx, by + 20, 100, 10)
        
        -- 4. Draw the text using the new outlined function
        drawOutlinedText(s, bx, by + 7, 100, "center", {1, 1, 1})
    end
end

return OptionsMenu