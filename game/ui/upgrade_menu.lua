-- game/ui/upgrade_menu.lua
local UpgradeMenu = {}
local Classes = require "game.data.classes"

-- Load font for upgrades
local upgradeFont = love.graphics.newFont("font.ttf", 14)

-- Helper function to draw outlined text
local function drawOutlinedText(text, x, y, width, align, textColor, outlineColor)
    love.graphics.setFont(upgradeFont)
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

function UpgradeMenu.getAvailableUpgrades(player)
    local currentClass = nil
    for _, class in pairs(Classes) do
        if class.name == player.tankName then
            currentClass = class
            break
        end
    end

    local available = {}
    if currentClass and currentClass.upgrades then
        for _, upgradeId in ipairs(currentClass.upgrades) do
            for _, class in pairs(Classes) do
                if class.id == upgradeId and player.level >= class.level then
                    table.insert(available, class)
                end
            end
        end
    end
    return available
end

function UpgradeMenu.draw(player, animationTimer)
    if not player then return end

    local upgrades = UpgradeMenu.getAvailableUpgrades(player)
    if #upgrades == 0 then return end

    -- Animation math: starts at -120 and moves to 20
    local targetX = 20
    local startX = -120
    local currentX = startX + (targetX - startX) * animationTimer

    local ux, uy = 20, 20

    local mx, my = love.mouse.getPosition()

    local y = 20
    local size = 100 -- Square size

    for i, class in ipairs(upgrades) do
        local rectY = y + ((i - 1) * 110) -- Spacing for squares
        
        -- Color logic
        local seed = 0
        for j = 1, #class.name do seed = seed + string.byte(class.name, j) end
        math.randomseed(seed)
        local r, g, b = math.random(40, 100)/100, math.random(40, 100)/100, math.random(40, 100)/100
        math.randomseed(os.time())

        -- 1. Square Background (Using animated currentX)
        local isHovered = mx >= ux and mx <= ux + 100 and my >= rectY and my <= rectY + 100
        if isHovered then
            love.graphics.setColor(r*1.5, g*1.5, b*1.5, 0.9 * animationTimer) -- Also fade alpha
        else
            love.graphics.setColor(r, g, b, 0.9 * animationTimer)
        end
        love.graphics.rectangle("fill", currentX, rectY, size, size, 4)
        
        -- 2. Shadow
        love.graphics.setColor(r * 0.7, g * 0.7, b * 0.7, 0.5 * animationTimer)
        love.graphics.rectangle("fill", currentX, rectY + (size * 0.66), size, size * 0.34, 0, 0, 0, 4, 4) 
        
        -- 3. Outline
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.3, 0.3, 0.3, animationTimer)
        love.graphics.rectangle("line", currentX, rectY, size, size, 4)
        
        -- 4. Text
        -- Use the outlined text function if available
        if drawOutlinedText then
            drawOutlinedText(class.name, currentX, rectY + (size/2 - 10), size, "center", {1, 1, 1, animationTimer}, {0, 0, 0, animationTimer})
        else
            love.graphics.setColor(1, 1, 1, animationTimer)
            love.graphics.printf(class.name, currentX, rectY + (size/2 - 10), size, "center")
        end
    end
end

return UpgradeMenu