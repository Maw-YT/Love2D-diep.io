-- game/ui/class_wheel.lua
local ClassWheel = {}
local Classes = require "game.data.classes"

local colors = {
    lightBlue = {0, 0.698, 0.882},
    green     = {0.463, 1, 0.482},
    red       = {0.945, 0.306, 0.329},
    yellow    = {1, 0.91, 0.412},
    purple    = {0.745, 0.514, 0.949},
    darkGrey  = {0.15, 0.15, 0.15},
    bgDark    = {0.05, 0.05, 0.08}
}

local tierColors = { colors.green, colors.lightBlue, colors.red, colors.purple }
local nameFont = love.graphics.newFont(10)
local titleFont = love.graphics.newFont(20)

-- Build the static tree once
local upgradeTree = nil

local function drawOutlinedText(text, x, y, width, align, textColor, font)
    font = font or nameFont
    love.graphics.setFont(font)
    love.graphics.setColor(0, 0, 0, textColor[4] or 1)
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

function ClassWheel.buildUpgradeTree()
    if upgradeTree then return upgradeTree end
    
    local root = { name = "Tank", class = Classes.Tank, tier = 1, children = {} }
    
    local function findNode(node, name)
        if node.name == name then return node end
        for _, child in ipairs(node.children) do
            local found = findNode(child, name)
            if found then return found end
        end
    end

    -- First pass: Add Tier 2s to Tank
    for name, class in pairs(Classes) do
        if class.level == 15 then
            table.insert(root.children, { name = name, class = class, tier = 2, children = {} })
        end
    end

    -- Subsequent passes: Build out Tier 3 and 4
    for tier = 3, 4 do
        local targetLevel = (tier == 3) and 30 or 45
        for name, class in pairs(Classes) do
            if class.level == targetLevel then
                -- Find parent by checking who has this class in their upgrades list
                for pName, pClass in pairs(Classes) do
                    if pClass.upgrades then
                        for _, upId in ipairs(pClass.upgrades) do
                            if upId == class.id then
                                local parentNode = findNode(root, pName)
                                if parentNode then
                                    table.insert(parentNode.children, { name = name, class = class, tier = tier, children = {} })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    upgradeTree = root
    return root
end

function ClassWheel.countLeaves(node)
    if #node.children == 0 then return 1 end
    local count = 0
    for _, child in ipairs(node.children) do
        count = count + ClassWheel.countLeaves(child)
    end
    return count
end

function ClassWheel.collectNodesByTier(tree)
    local tiers = {{}, {}, {}, {}}
    local function assignAngles(node, startA, endA)
        table.insert(tiers[node.tier], {
            name = node.name, class = node.class,
            startAngle = startA, endAngle = endA, tier = node.tier
        })
        if #node.children > 0 then
            local totalLeaves = ClassWheel.countLeaves(node)
            local currentA = startA
            for _, child in ipairs(node.children) do
                local span = (endA - startA) * (ClassWheel.countLeaves(child) / totalLeaves)
                assignAngles(child, currentA, currentA + span)
                currentA = currentA + span
            end
        end
    end
    assignAngles(tree, 0, 2 * math.pi)
    return tiers
end

function ClassWheel.drawArcFill(centerX, centerY, innerR, outerR, startAngle, endAngle, color, alpha)
    alpha = alpha or 1
    
    -- 1. Create the Ring Mask
    -- We use 'increment' for the big circle and 'decrement' for the small one.
    -- This leaves a value of 1 ONLY in the area between them.
    love.graphics.stencil(function()
        love.graphics.circle("fill", centerX, centerY, outerR)
        love.graphics.circle("fill", centerX, centerY, innerR)
    end, "increment", 1)

    -- 2. Set the test to only draw where the value is exactly 1
    -- (The outer circle made it 1, the inner circle subtracted it back to 0)
    love.graphics.setStencilTest("equal", 1)
    
    -- 3. Draw the Pie Slice
    love.graphics.setColor(color[1], color[2], color[3], 0.9 * alpha)
    
    local segments = 64
    local vertices = {centerX, centerY} -- Pivot at center to create the slice
    
    for i = 0, segments do
        local t = i / segments
        local angle = startAngle + t * (endAngle - startAngle)
        -- Overshoot by 2 pixels to ensure it reaches the dark outline
        table.insert(vertices, centerX + math.cos(angle) * (outerR + 2))
        table.insert(vertices, centerY + math.sin(angle) * (outerR + 2))
    end
    
    love.graphics.polygon("fill", vertices)
    
    -- 4. Reset for the next drawing operation
    love.graphics.setStencilTest()
end

-- Draw arc outline (stroke only)
function ClassWheel.drawArcOutline(centerX, centerY, innerR, outerR, startAngle, endAngle, alpha)
    love.graphics.setColor(colors.darkGrey[1], colors.darkGrey[2], colors.darkGrey[3], alpha)
    love.graphics.setLineWidth(2)
    love.graphics.setLineJoin("miter")
    
    -- Use the same math for lines to ensure perfect alignment
    love.graphics.arc("line", "open", centerX, centerY, outerR, startAngle, endAngle, 64)
    love.graphics.arc("line", "open", centerX, centerY, innerR, startAngle, endAngle, 64)
    
    -- Radial lines
    love.graphics.line(
        centerX + math.cos(startAngle) * innerR, centerY + math.sin(startAngle) * innerR,
        centerX + math.cos(startAngle) * outerR, centerY + math.sin(startAngle) * outerR
    )
    love.graphics.line(
        centerX + math.cos(endAngle) * innerR, centerY + math.sin(endAngle) * innerR,
        centerX + math.cos(endAngle) * outerR, centerY + math.sin(endAngle) * outerR
    )
end

function ClassWheel.draw(player, animationTimer)
    local screenW, screenH = love.graphics.getDimensions()
    local centerX, centerY = screenW / 2, screenH / 2 + 10
    
    local tree = ClassWheel.buildUpgradeTree()
    local tiers = ClassWheel.collectNodesByTier(tree)
    local ringRadii = {45, 110, 185, 260, 330}
    
    -- Background
    love.graphics.setColor(0.05, 0.05, 0.08, 0.9 * animationTimer)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- PHASE 1: Draw all FILLS first (with 0.5px Inset)
    -- This creates a solid color base without any edge bleed
    for tier = 4, 1, -1 do
        for _, node in ipairs(tiers[tier]) do
            local isHovered = (hoverTier == tier and hoverNode == node)
            local color = tierColors[tier]
            if isHovered then
                color = {math.min(1, color[1] * 1.15), math.min(1, color[2] * 1.15), math.min(1, color[3] * 1.15)}
            end
            
            if tier == 1 then
                love.graphics.setColor(color[1], color[2], color[3], 0.9 * animationTimer)
                -- Inset the center circle by 0.5px to stay under the outline
                love.graphics.circle("fill", centerX, centerY, (isHovered and ringRadii[1] + 4 or ringRadii[1]) - 0.5)
            else
                -- Use drawArcFill with an internal 0.5px inset
                ClassWheel.drawArcFill(centerX, centerY, ringRadii[tier] + 0.5, ringRadii[tier + 1] - 0.5, 
                    node.startAngle + 0.001, node.endAngle - 0.001, color, animationTimer)
            end
        end
    end

    -- PHASE 2: Draw all OUTLINES on top (Full size)
    -- Drawing these last ensures the dark grey lines sit squarely over the fill edges
    for tier = 4, 1, -1 do
        for _, node in ipairs(tiers[tier]) do
            local isHovered = (hoverTier == tier and hoverNode == node)
            
            if tier == 1 then
                local radius = isHovered and ringRadii[1] + 4 or ringRadii[1]
                love.graphics.setColor(colors.darkGrey[1], colors.darkGrey[2], colors.darkGrey[3], animationTimer)
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", centerX, centerY, radius)
            else
                -- Draw the outline at full size to overlap the inset fills
                ClassWheel.drawArcOutline(centerX, centerY, ringRadii[tier], ringRadii[tier + 1],
                    node.startAngle, node.endAngle, animationTimer)
            end
        end
    end

    -- PHASE 3: Draw text labels with vibrant colors
    for tier = 1, 4 do
        for _, node in ipairs(tiers[tier]) do
            local midAngle = (node.startAngle + node.endAngle) / 2
            
            local textR = 0
            if tier > 1 then
                textR = (ringRadii[tier] + ringRadii[tier + 1]) / 2
            end
            
            local tx = centerX + math.cos(midAngle) * textR
            local ty = centerY + math.sin(midAngle) * textR
            
            local isLocked = player.level < node.class.level
            local isCurrent = (player.tankName == node.name)
            
            -- Color selection logic
            local textColor = {1, 1, 1, animationTimer} -- Default White
            if isCurrent then
                textColor = {1, 1, 0.4, animationTimer} -- Vibrant Yellow/Gold
            elseif isLocked then
                textColor = {0.6, 0.6, 0.6, animationTimer} -- Lighter Grey for better contrast
            end
            
            -- Draw the text
            local verticalOffset = (tier == 1) and 0 or 7
            drawOutlinedText(node.name, tx - 50, ty - verticalOffset, 100, "center", textColor, nameFont)
            
            if tier > 1 then
                local levelColor = isLocked and {0.4, 0.4, 0.4, animationTimer} or {0.8, 0.8, 0.8, animationTimer}
                drawOutlinedText("Lv." .. node.class.level, tx - 30, ty + 5, 60, "center", levelColor, nameFont)
            end
        end
    end
end

return ClassWheel