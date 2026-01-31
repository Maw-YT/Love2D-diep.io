-- game/systems/ui/stat_menu.lua
local StatMenu = {}

function StatMenu.draw(ui, player)
    local x, y = ui.statMenuOffset, love.graphics.getHeight() - 250
    local width, height = 200, 25
    local buttonWidth, buttonHeight = 35, 25 -- Wider button style
    local pillRadius = 12 

    love.graphics.printf("Points: " .. player.statPoints, x, y - 25, width + buttonWidth, "left")

    for i, stat in ipairs(ui.statOptions) do
        local rectY = y + (i - 1) * (height + 5)
        local barX = x 
        local btnX = x + width - 20 -- Removed the +5 gap so they touch
        
        -- 1. Progress Bar Background (Fully Rounded)
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", barX, rectY, width, height, pillRadius)

        -- 2. Progress Fill
        local level = player.stats[stat.id] or 0
        if level > 0 then
            love.graphics.setColor(stat.color)
            love.graphics.rectangle("fill", barX, rectY, (width / 8) * level, height, pillRadius)
        end
        
        -- 3. Outline for Bar
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", barX, rectY, width, height, pillRadius)

        -- 4. Plus Button (Fully Rounded, touching the bar)
        love.graphics.setColor(stat.color)
        love.graphics.rectangle("fill", btnX, rectY, buttonWidth, buttonHeight, pillRadius)
        
        -- Plus Sign icon
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", btnX + (buttonWidth/2 - 6.5), rectY + 11, 13, 3)
        love.graphics.rectangle("fill", btnX + (buttonWidth/2 - 1.5), rectY + 6, 3, 13)

        -- 5. Outline for Button
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("line", btnX, rectY, buttonWidth, buttonHeight, pillRadius)

        -- Stat Name Text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(stat.name, barX + 5, rectY + 6, width, "left")
    end
end

return StatMenu