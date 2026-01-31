-- game/ui/upgrade_menu.lua
local UpgradeMenu = {}
local Classes = require "game.data.classes"

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

function UpgradeMenu.draw(player)
    local upgrades = UpgradeMenu.getAvailableUpgrades(player)
    local x, y = 20, 20
    
    for i, class in ipairs(upgrades) do
        local rectY = y + ((i-1) * 55)
        -- Diep style button
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", x, rectY, 140, 50, 4)
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("fill", x, rectY + 34, 140, 16) -- shadow
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(class.name, x, rectY + 18, 140, "center")
    end
end

return UpgradeMenu