-- game/systems/ui_manager.lua
local UIManager = {}
UIManager.__index = UIManager

local Classes = require "game.data.classes"

function UIManager:new(game)
    local self = setmetatable({}, UIManager)
    self.game = game
    
    -- Initialize UI components here instead of game/init.lua
    self.xpBar = game.res.XPBar:new()

    -- Start offset at -300 so it begins off-screen to the left
    self.statMenuOffset = -300
    
    self.menus = {
        MENU = {
            playButton = game.res.Button:new("PLAY", 0, 0, 200, 50, function() 
                game:startGame() 
            end),
            -- New Options Button
            optionsButton = game.res.Button:new("OPTIONS", 0, 0, 200, 50, function()
                game.state = "OPTIONS"
            end)
        },
        OPTIONS = {
            backButton = game.res.Button:new("BACK", 0, 0, 200, 50, function()
                game.state = "MENU"
            end)
        }
    }
    -- Define the upgrade options
    self.statOptions = {
        { id = "movement_speed",     name = "Movement Speed",    color = {0, 1, 0} },
        { id = "reload",             name = "Reload Speed",      color = {1, 0.5, 0} },
        { id = "bullet_damage",      name = "Bullet Damage",     color = {1, 0, 0} },
        { id = "bullet_speed",       name = "Bullet Speed",      color = {0, 0.5, 1}},
        { id = "bullet_penetration", name = "Penetration",       color = {1, 1, 0} },
        { id = "max_health",         name = "Max Health",        color = {0, 1, 1} }
    }
    return self
end

function UIManager:update(dt, state)
    local screenW, screenH = love.graphics.getDimensions()
    local mx, my = love.mouse.getPosition()
    local targetX = -300 -- Hidden position
    local isHovering = false -- Track if we are hovering over any button

    if self.game.player and self.game.player.statPoints > 0 then
        targetX = 20 -- Visible position
    end

    -- Smoothly interpolate the offset (speed of 10 can be adjusted)
    self.statMenuOffset = self.statMenuOffset + (targetX - self.statMenuOffset) * 10 * dt
    
    if self.menus[state] then
        for name, element in pairs(self.menus[state]) do
            if name == "playButton" then
                element.x, element.y = screenW / 2 - 100, screenH / 2 - 30
            elseif name == "optionsButton" then
                element.x, element.y = screenW / 2 - 100, screenH / 2 + 30
            elseif name == "backButton" then
                element.x, element.y = screenW / 2 - 100, screenH - 100
            end
            element:update(dt)

            -- Hover check for standard buttons
            if mx >= element.x and mx <= element.x + element.width and 
               my >= element.y and my <= element.y + element.height then
                isHovering = true
            end
        end
    end

    -- 3. Check Stat Upgrade Buttons (if visible)
    if state == "PLAYING" and self.statMenuOffset > -250 then
        local startX, startY = self.statMenuOffset, love.graphics.getHeight() - 250
        local buttonSize = 25
        for i = 1, #self.statOptions do
            local rectY = startY + (i - 1) * (25 + 5)
            if mx >= startX and mx <= startX + buttonSize and 
               my >= rectY and my <= rectY + buttonSize then
                isHovering = true
            end
        end
    end

    -- 4. Check Tank Upgrade Buttons (Top Left)
    if state == "PLAYING" and self.game.player then
        local player = self.game.player
        local ux, uy = 20, 20 -- Starting position matching drawTankUpgradeMenu
        local i = 0
        
        -- We need the Classes data to know which buttons are actually visible
        local Classes = require "game.data.classes"
        local currentClass = nil
        for _, class in pairs(Classes) do
            if class.name == player.tankName then
                currentClass = class
                break
            end
        end

        if currentClass and currentClass.upgrades then
            for _, upgradeId in ipairs(currentClass.upgrades) do
                -- Find the class data for this specific ID to check level requirements
                local targetClass = nil
                for _, class in pairs(Classes) do
                    if class.id == upgradeId then
                        targetClass = class
                        break
                    end
                end

                if targetClass and player.level >= targetClass.level then
                    local rectY = uy + (i * 55)
                    -- Check if mouse is over this upgrade box (140x50 matching draw code)
                    if mx >= ux and mx <= ux + 140 and my >= rectY and my <= rectY + 50 then
                        isHovering = true
                    end
                    i = i + 1
                end
            end
        end
    end

    -- 5. Check Style Selection Buttons in OPTIONS
    if state == "OPTIONS" then
        local styles = {"New", "Old"}
        for i, _ in ipairs(styles) do
            local bx, by = screenW/2 - 50 + (i-1) * 110, 200
            if mx >= bx and mx <= bx + 100 and my >= by and my <= by + 30 then
                isHovering = true
            end
        end
    end

    -- 6. Apply the Cursor
    if isHovering then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        love.mouse.setCursor() -- Resets to default arrow
    end
end

function UIManager:draw(state, player)
    local dt = love.timer.getDelta()
    
    if state == "MENU" then
        self:drawMenuOverlay()
        for _, btn in pairs(self.menus.MENU) do btn:draw() end
    elseif state == "OPTIONS" then
        self:drawOptionsMenu()
        for _, btn in pairs(self.menus.OPTIONS) do btn:draw() end
    elseif state == "PLAYING" then
        self:drawHUD(player, dt)
        if player and player.isDead then
            self:drawRespawnScreen()
        end
    elseif state == "PAUSED" then
        -- Draw the HUD in the background so you can see your stats
        self:drawHUD(player, dt)
        self:drawPauseOverlay()
    end
end

-- Dedicated function for things like XP bars, score, and stat menus
function UIManager:drawHUD(player, dt)
    if not player or player.isDead then return end
    
    -- Draw the XP Bar
    self.xpBar:draw(player, dt)

    -- Draw if the menu is at all visible on screen
    if self.statMenuOffset > -280 then
        self:drawStatMenu(player)
    end

    -- Draw Tank Upgrades
    self:drawTankUpgradeMenu(player)

    -- NEW: Draw the Minimap
    self:drawMinimap(player)
end

function UIManager:drawStatMenu(player)
    -- Use the animated offset for 'x'
    local x, y = self.statMenuOffset, love.graphics.getHeight() - 250
    local width, height = 200, 25
    local buttonSize = 25 

    love.graphics.printf("Points: " .. player.statPoints, x, y - 25, width + buttonSize, "left")

    for i, stat in ipairs(self.statOptions) do
        local rectY = y + (i - 1) * (height + 5)
        
        -- Draw Button
        love.graphics.setColor(stat.color)
        love.graphics.rectangle("fill", x, rectY, buttonSize, buttonSize, 4)
        
        -- Draw Cross
        love.graphics.setColor(0, 0, 0, 0.5)
        local p = 6
        love.graphics.rectangle("fill", x + p, rectY + (buttonSize/2 - 1), buttonSize - (p*2), 2)
        love.graphics.rectangle("fill", x + (buttonSize/2 - 1), rectY + p, 2, buttonSize - (p*2))

        -- Draw Progress Bar
        local barX = x + buttonSize + 5
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", barX, rectY, width, height, 4)

        local level = player.stats[stat.id] or 0
        if level > 0 then
            love.graphics.setColor(stat.color)
            love.graphics.rectangle("fill", barX, rectY, (width / 8) * level, height, 4)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(stat.name .. " ["..level.."]", barX + 5, rectY + 6, width, "left")
    end
end

function UIManager:drawMenuOverlay()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("DIEP.IO (Love2D Edition)", 0, h/2 - 80, w, "center")
    love.graphics.printf("Created by Maw (not owner of diep.io)", 0, h/2 + 200, w, "center")
end

function UIManager:drawOptionsMenu()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SETTINGS", 0, 100, w, "center")
    
    -- Style Selector Label
    love.graphics.printf("Style:", w/2 - 150, 205, 100, "left")
    
    -- Style Buttons (The "Dropdown" replacement)
    local styles = {"New", "Old"}
    for i, s in ipairs(styles) do
        local bx, by = w/2 - 50 + (i-1) * 110, 200
        
        -- Highlight current selection
        if self.game.style == s then
            love.graphics.setColor(0, 0.7, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.3)
        end
        
        love.graphics.rectangle("fill", bx, by, 100, 30, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(s, bx, by + 7, 100, "center")
    end
end

function UIManager:mousepressed(x, y, button)
    local state = self.game.state
    -- 1. Handle regular menu buttons
    if self.menus[state] then
        for _, element in pairs(self.menus[state]) do
            if element.mousepressed then element:mousepressed(x, y, button) end
        end
    end

    -- 2. Handle Style selection in OPTIONS state
    if state == "OPTIONS" then
        local w = love.graphics.getWidth()
        local styles = {"New", "Old"}
        for i, s in ipairs(styles) do
            local bx, by = w/2 - 50 + (i-1) * 110, 200
            if x >= bx and x <= bx + 100 and y >= by and y <= by + 30 then
                self.game.style = s
            end
        end
    end

    local player = self.game.player
    -- Allow clicking as long as the menu is mostly on screen
    if self.game.state == "PLAYING" and player and self.statMenuOffset > 0 then
        local startX, startY = self.statMenuOffset, love.graphics.getHeight() - 250
        local buttonSize = 25
        local height = 25

        for i, stat in ipairs(self.statOptions) do
            local rectY = startY + (i - 1) * (height + 5)
            
            if x >= startX and x <= startX + buttonSize and y >= rectY and y <= rectY + buttonSize then
                if (player.stats[stat.id] or 0) < 8 and player.statPoints > 0 then 
                    player.stats[stat.id] = (player.stats[stat.id] or 0) + 1
                    player.statPoints = player.statPoints - 1
                    self:applyStatBoost(player, stat.id)
                end
                return 
            end
        end
    end
    if self.game.state == "PLAYING" then
        local ux, uy = 20, 20
        local i = 0
        
        -- Get current class
        local currentClass = nil
        for _, class in pairs(Classes) do
            if player and class.name == player.tankName then
                currentClass = class
                break
            end
        end

        if currentClass and currentClass.upgrades then
            for _, upgradeId in ipairs(currentClass.upgrades) do
                -- Get the data for the upgrade option
                local targetClass = nil
                for _, class in pairs(Classes) do
                    if class.id == upgradeId then
                        targetClass = class
                        break
                    end
                end

                if targetClass and player.level >= targetClass.level then
                    local rectY = uy + (i * 55)
                    if x >= ux and x <= ux + 140 and y >= rectY and y <= rectY + 50 then
                        self:upgradeTank(player, targetClass)
                        break
                    end
                    i = i + 1
                end
            end
        end
    end
end

function UIManager:upgradeTank(player, class)
    player.tankName = class.name
    player.barrels = {}
    
    -- 1. Set the new base fire rate from the class
    player.fire_rate = class.fire_rate
    
    -- 2. Re-apply the reload stat modifiers (10% faster per point)
    local reloadLevel = player.stats["reload"] or 0
    if reloadLevel > 0 then
        -- This applies the 0.9 multiplier for every level invested
        player.fire_rate = player.fire_rate * (0.9 ^ reloadLevel)
    end

    -- 3. Rebuild the barrels
    for _, b in ipairs(class.barrels) do
        table.insert(player.barrels, self.game.res.Barrel:new(
            player, 
            b.delay, 
            b.type, 
            b
        ))
    end
end

function UIManager:applyStatBoost(player, statId)
    if statId == "movement_speed" then
        player.accel = player.accel + 200
    elseif statId == "max_health" then
        player.max_health = player.max_health + 20
        player.health = player.health + 20
    elseif statId == "reload" then
        player.fire_rate = player.fire_rate * 0.9 -- 10% faster
    end
end

function UIManager:drawPauseOverlay()
    local w, h = love.graphics.getDimensions()
    
    -- Dim the screen
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("GAME PAUSED", 0, h/2 - 20, w, "center")
    love.graphics.printf("Press ESC to Resume", 0, h/2 + 20, w, "center")
end

-- NEW: Function to render the death screen text
function UIManager:drawRespawnScreen()
    local w, h = love.graphics.getDimensions()
    
    -- Optional: Darken the screen slightly while dead
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("YOU DIED", 0, h/2 - 40, w, "center")
    
    -- Show the countdown rounded to 1 decimal place
    local timeRemaining = math.max(0, self.game.respawnTimer)
    love.graphics.printf(string.format("Respawning in %.1f seconds...", timeRemaining), 0, h/2, w, "center")
end

function UIManager:drawMinimap(player)
    local arena = self.game.arena
    if not arena then return end

    local mapSize = 150 -- Size of the minimap square
    local padding = 20
    local screenW, screenH = love.graphics.getDimensions()
    
    -- Position in bottom right
    local mx = screenW - mapSize - padding
    local my = screenH - mapSize - padding

    -- 1. Draw Background
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", mx, my, mapSize, mapSize)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", mx, my, mapSize, mapSize)

    -- Scale factor
    local scaleX = mapSize / arena.width
    local scaleY = mapSize / arena.height

    -- 2. Draw Nest (Center Area)
    local nestSize = arena.width * 0.15
    love.graphics.setColor(0.5, 0.5, 0.9, 0.4)
    love.graphics.rectangle("fill", 
        mx + (arena.width / 2 - nestSize / 2) * scaleX,
        my + (arena.height / 2 - nestSize / 2) * scaleY,
        nestSize * scaleX,
        nestSize * scaleY
    )

    -- 3. Draw Player Position
    if player then
        local px = mx + (player.x * scaleX)
        local py = my + (player.y * scaleY)
        
        -- Clamp player dot within map bounds
        px = math.max(mx, math.min(mx + mapSize, px))
        py = math.max(my, math.min(my + mapSize, py))

        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", px, py, 3)
    end
    
    love.graphics.setLineWidth(1)
end

function UIManager:drawTankUpgradeMenu(player)
    local x, y = 20, 20
    local i = 0
    
    -- Find the current class data for the player
    local currentClass = nil
    for _, class in pairs(Classes) do
        if class.name == player.tankName then
            currentClass = class
            break
        end
    end

    if not currentClass or not currentClass.upgrades then return end

    -- Only iterate through IDs allowed by the current class
    for _, upgradeId in ipairs(currentClass.upgrades) do
        -- Find the class data for this specific ID
        local targetClass = nil
        for _, class in pairs(Classes) do
            if class.id == upgradeId then
                targetClass = class
                break
            end
        end

        if targetClass and player.level >= targetClass.level then
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", x, y + (i * 55), 140, 50, 4)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(targetClass.name, x, y + (i * 55) + 18, 140, "center")
            i = i + 1
        end
    end
end

return UIManager