-- game/systems/ui_manager.lua
local UIManager = {}
UIManager.__index = UIManager

local Classes = require "game.data.classes"
local Minimap = require "game.ui.minimap"
local StatMenu = require "game.ui.stat_menu"
local UpgradeMenu = require "game.ui.upgrade_menu"
local MainMenu = require "game.ui.main_menu"
local OptionsMenu = require "game.ui.options_menu"
local Leaderboard = require "game.ui.leaderboard"

-- Initialize font and outlined text helper
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

function UIManager:new(game)
    local self = setmetatable({}, UIManager)
    self.game = game
    
    -- Initialize UI components here instead of game/init.lua
    self.xpBar = game.res.XPBar:new()
    self.leaderboard = Leaderboard:new()

    -- Start offset at -300 so it begins off-screen to the left
    self.statMenuOffset = -300
    self.upgradeAnimationTimer = 0 -- Track animation progress
    
    -- Initialize menu button instances
    self.menus = {
        MENU = MainMenu.get(game),
        OPTIONS = OptionsMenu.get(game)
    }
    -- Define the upgrade options
    self.statOptions = {
        { id = "movement_speed",     name = "Movement Speed",    color = {0, 1, 0} },
        { id = "reload",             name = "Reload Speed",      color = {1, 0.5, 0} },
        { id = "bullet_damage",      name = "Bullet Damage",     color = {1, 0, 0} },
        { id = "bullet_speed",       name = "Bullet Speed",      color = {0, 0.5, 1}},
        { id = "bullet_penetration", name = "Bullet Penetration",color = {1, 1, 0} },
        { id = "max_health",         name = "Max Health",        color = {0, 1, 1} },
        { id = "body_damage",        name = "Body Damage",       color = {1, 0.3, 0.3} },
        { id = "health_regen",       name = "Health Regen",      color = {1, 0.4, 0.8} }
    }
    return self
end

function UIManager:update(dt, state)
    local screenW, screenH = love.graphics.getDimensions()
    local mx, my = love.mouse.getPosition()
    local targetX = -300 -- Hidden position
    local isHovering = false -- Track if we are hovering over any button
    -- Standard button width is 200. We find the center of the screen.
    local centerX = screenW / 2 - 100

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
            elseif name == "FFABtn" then
                element.x, element.y = centerX, screenH / 2 - 90
            elseif name == "SandboxBtn" then
                element.x, element.y = centerX + 105, screenH / 2 - 90
            end
            element:update(dt)

            -- Check for hover to update cursor
            if element.isHovered then
                isHovering = true
            end
        end
    end

    -- 3. Check Stat Upgrade Buttons (if visible)
    if state == "PLAYING" and self.statMenuOffset > -250 then
        local startX, startY = self.statMenuOffset, love.graphics.getHeight() - 250
        local barWidth = 200
        local buttonWidth = 35
        for i = 1, #self.statOptions do
            local rectY = startY + (i - 1) * (25 + 5)
            local btnX = startX + barWidth - 20 -- Check the right side
            
            if mx >= btnX and mx <= btnX + buttonWidth and 
            my >= rectY and my <= rectY + 25 then
                isHovering = true
            end
        end
    end
    if self.game.player then
        -- Update the animation timer
        local upgrades = UpgradeMenu.getAvailableUpgrades(self.game.player)
        if #upgrades > 0 then
            -- Move toward 1 (fully visible)
            self.upgradeAnimationTimer = math.min(1, self.upgradeAnimationTimer + dt * 5)
        else
            -- Reset to 0 when no upgrades are available
            self.upgradeAnimationTimer = 0
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
                    local rectY = uy + (i * 110) -- Match the new spacing
                    if mx >= ux and mx <= ux + 100 and my >= rectY and my <= rectY + 100 then
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
    -- 1. Handle Game State Overlays
    if state == "MENU" then
        MainMenu.drawOverlay()
        for _, btn in pairs(self.menus.MENU) do btn:draw() end
        
    elseif state == "OPTIONS" then
        OptionsMenu.draw(self.game)
        for _, btn in pairs(self.menus.OPTIONS) do btn:draw() end
        
    elseif state == "PAUSED" then
        -- Use the previously unused pause overlay
        self:drawPauseOverlay()
        
    elseif state == "PLAYING" and player then
        -- Main Gameplay UI
        self.xpBar:draw(player, love.timer.getDelta())
        
        if self.statMenuOffset > -280 then 
            StatMenu.draw(self, player) 
        end
        
        -- Pass the animation timer to the draw function
        UpgradeMenu.draw(player, self.upgradeAnimationTimer)
        Minimap.draw(self.game, player)
        
        -- Draw leaderboard (top 10 scores)
        self.leaderboard:draw(player, self.game.arena.bots)

        -- 2. Use the previously unused respawn screen
        if player.isDead then 
            self:drawRespawnScreen() 
        end
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
    if self.game.state == "PLAYING" and player and self.statMenuOffset > 0 then
        local startX, startY = self.statMenuOffset, love.graphics.getHeight() - 250
        local barWidth = 200      -- Must match the width in stat_menu.lua
        local buttonWidth = 35    -- Must match the width in stat_menu.lua
        local height = 25

        for i, stat in ipairs(self.statOptions) do
            local rectY = startY + (i - 1) * (height + 5)
            
            -- FIX: Look for the click on the RIGHT side of the bar
            local btnX = startX + barWidth - 20
            
            if x >= btnX and x <= btnX + buttonWidth and y >= rectY and y <= rectY + height then
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
                    local rectY = uy + (i * 110) -- Match the new spacing
                    if x >= ux and x <= ux + 100 and y >= rectY and y <= rectY + 100 then
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
    if statId == "max_health" then
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
    
    -- Using outlined text for the pause menu
    drawOutlinedText("GAME PAUSED", 0, h/2 - 20, w, "center", {1, 1, 1})
    drawOutlinedText("Press ESC to Resume", 0, h/2 + 20, w, "center", {1, 1, 1})
end

-- Function to render the death screen text
function UIManager:drawRespawnScreen()
    local w, h = love.graphics.getDimensions()
    
    -- Optional: Darken the screen slightly while dead
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Using outlined text for the death screen
    drawOutlinedText("YOU DIED", 0, h/2 - 40, w, "center", {1, 0.2, 0.2}) -- Slightly red tint
    
    -- Show the countdown rounded to 1 decimal place
    local timeRemaining = math.max(0, self.game.respawnTimer)
    local respawnMsg = string.format("Respawning in %.1f seconds...", timeRemaining)
    drawOutlinedText(respawnMsg, 0, h/2, w, "center", {1, 1, 1})
end

return UIManager