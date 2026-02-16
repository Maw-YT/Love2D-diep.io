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

    local targetX = 20
    local startX = -120
    local currentX = startX + (targetX - startX) * animationTimer

    local mx, my = love.mouse.getPosition()
    local y = 20
    local size = 100 

    for i, class in ipairs(upgrades) do
        local rectY = y + ((i - 1) * 110)
        
        -- Generate background color based on class name
        local seed = 0
        for j = 1, #class.name do seed = seed + string.byte(class.name, j) end
        math.randomseed(seed)
        local r, g, b = math.random(40, 100)/100, math.random(40, 100)/100, math.random(40, 100)/100
        math.randomseed(os.time())

        -- 1. Square Background
        local isHovered = mx >= currentX and mx <= currentX + size and my >= rectY and my <= rectY + size
        if isHovered then
            love.graphics.setColor(r*1.2, g*1.2, b*1.2, 0.9 * animationTimer)
        else
            love.graphics.setColor(r, g, b, 0.9 * animationTimer)
        end
        love.graphics.rectangle("fill", currentX, rectY, size, size, 4)
        
        -- 2. Tank Preview
        -- We create a temporary "mock" player to use the existing Player:draw logic
        local previewTank = {
            x = currentX + size/2,
            y = rectY + size/2 - 10,
            angle = -math.pi/4, -- Tilt it slightly for style
            radius = 15,        -- Scaled down
            color = player.color,
            outline_color = player.outline_color,
            barrels = {},
            addons = {},
            invisAlpha = 1.0,
            hitTimer = 0
        }

        -- Load barrels for this specific class preview
        if class.barrels then
            for _, b in ipairs(class.barrels) do
                table.insert(previewTank.barrels, player.res.Barrel:new(previewTank, b.delay, b.type, b))
            end
        end

        -- Render the preview using the logic from Player.lua (re-implemented for local scope)
        love.graphics.push()
        love.graphics.translate(previewTank.x, previewTank.y)
        love.graphics.rotate(previewTank.angle)
        
        for _, barrel in ipairs(previewTank.barrels) do
            barrel:draw(animationTimer, 0, "New")
        end

        love.graphics.setColor(previewTank.color[1], previewTank.color[2], previewTank.color[3], animationTimer)
        love.graphics.circle("fill", 0, 0, previewTank.radius)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(previewTank.outline_color[1], previewTank.outline_color[2], previewTank.outline_color[3], animationTimer)
        love.graphics.circle("line", 0, 0, previewTank.radius)
        love.graphics.pop()

        -- 3. Shadow Overlay (bottom part of button)
        love.graphics.setColor(0, 0, 0, 0.2 * animationTimer)
        love.graphics.rectangle("fill", currentX, rectY + (size * 0.7), size, size * 0.3, 0, 0, 0, 4, 4) 
        
        -- 4. Text
        if drawOutlinedText then
            drawOutlinedText(class.name, currentX, rectY + (size * 0.75), size, "center", {1, 1, 1, animationTimer}, {0, 0, 0, animationTimer})
        end

        -- 5. Outer Border
        love.graphics.setLineWidth(3)
        love.graphics.setColor(0.3, 0.3, 0.3, 1 * animationTimer)
        love.graphics.rectangle("line", currentX, rectY, size, size, 4)
    end
end

return UpgradeMenu