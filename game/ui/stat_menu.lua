-- game/systems/ui/stat_menu.lua
local StatMenu = {}

-- Load fonts
local statFont = love.graphics.newFont("font.ttf", 14)
-- FIX: Create the font and immediately set the filter to "linear" to stop pixelation
local pointsFont = love.graphics.newFont("font.ttf", 24)
pointsFont:setFilter("linear", "linear")

-- Helper function to draw outlined text with ROTATION
local function drawOutlinedText(text, x, y, width, align, font, textColor, rotation)
    love.graphics.setFont(font)
    rotation = rotation or 0 -- Angle in radians
    
    love.graphics.push()
    -- Move to the position where the text should be
    love.graphics.translate(x, y)
    -- Rotate the coordinate system
    love.graphics.rotate(rotation)
    
    -- Draw outline
    love.graphics.setColor(0, 0, 0)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                -- Since we translated, we draw at 0, 0
                love.graphics.printf(text, dx, dy, width, align)
            end
        end
    end
    
    -- Draw main text
    love.graphics.setColor(textColor)
    love.graphics.printf(text, 0, 0, width, align)
    
    love.graphics.pop()
end

function StatMenu.draw(ui, player)
    local x, y = ui.statMenuOffset, love.graphics.getHeight() - 250
    local width, height = 200, 25
    local buttonWidth = 35
    local pillRadius = 12 

    local mx, my = love.mouse.getPosition()

    -- This will now use the filtered pointsFont for the rotated "(number)x" text
    local pointsText = player.statPoints .. "x"
    local rotationAngle = -0.15 
    drawOutlinedText(pointsText, ui.statMenuOffset + 215, love.graphics.getHeight() - 280, 60, "right", pointsFont, {1, 1, 1}, rotationAngle)

    for i, stat in ipairs(ui.statOptions) do
        local rectY = y + (i - 1) * (height + 5)
        local barX = x 
        local btnX = x + width - 20 
        
        -- 2. Progress Bar Background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", barX, rectY, width, height, pillRadius)

        -- 3. Progress Fill & Dividers
        local level = player.stats[stat.id] or 0
        if level > 0 then
            local fillWidth = (width / 8) * level
            love.graphics.setColor(stat.color)
            love.graphics.rectangle("fill", barX, rectY, fillWidth, height, pillRadius)

            love.graphics.setLineWidth(1)
            love.graphics.setColor(0, 0, 0, 0.3)
            love.graphics.setScissor(barX, rectY, fillWidth, height)
            for j = 1, level - 1 do
                local lineX = barX + (width / 8) * j
                love.graphics.line(lineX, rectY, lineX, rectY + height)
            end
            love.graphics.setScissor()
        end
        
        -- 4. Outline for Bar
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", barX, rectY, width, height, pillRadius)

        local isHovered = mx >= btnX and mx <= btnX + buttonWidth and my >= rectY and my <= rectY + 25
        -- 5. Plus Button
        if isHovered then
            love.graphics.setColor(stat.color[1]*1.5, stat.color[2]*1.5, stat.color[3]*1.5)
        else
            love.graphics.setColor(stat.color)
        end
        love.graphics.rectangle("fill", btnX, rectY, buttonWidth, height, pillRadius)
        
        -- UPDATED: Plus Sign icon color changed to 0.3, 0.3, 0.3
        love.graphics.setColor(0.3, 0.3, 0.3) 
        love.graphics.rectangle("fill", btnX + (buttonWidth/2 - 6.5), rectY + 11, 13, 3)
        love.graphics.rectangle("fill", btnX + (buttonWidth/2 - 1.5), rectY + 6, 3, 13)

        -- 6. Outline for Button
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("line", btnX, rectY, buttonWidth, height, pillRadius)

        -- 7. Stat Name Text (Centered, No rotation)
        drawOutlinedText(stat.name, barX, rectY + 6, width, "center", statFont, {1, 1, 1}, 0)
    end
end

return StatMenu