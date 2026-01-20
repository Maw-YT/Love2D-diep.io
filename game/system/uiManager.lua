-- game/systems/ui_manager.lua
local UIManager = {}
UIManager.__index = UIManager

local Classes = require "game.data.classes"

function UIManager:new(game)
    local self = setmetatable({}, UIManager)
    self.game = game
    
    -- Initialize UI components here instead of game/init.lua
    self.xpBar = game.res.XPBar:new()
    
    self.menus = {
        MENU = {
            playButton = game.res.Button:new("PLAY", 0, 0, 200, 50, function() 
                game:startGame() 
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
    
    if self.menus[state] then
        for name, element in pairs(self.menus[state]) do
            if name == "playButton" then
                element.x = screenW / 2 - 100
                element.y = screenH / 2
            end
            element:update(dt)
        end
    end
end

function UIManager:draw(state, player)
    local dt = love.timer.getDelta()
    
    if state == "MENU" then
        self:drawMenuOverlay()
        if self.menus.MENU.playButton then
            self.menus.MENU.playButton:draw()
        end
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

    -- DRAW STAT MENU
    if player.statPoints > 0 then
        self:drawStatMenu(player)
    end

    -- Draw Tank Upgrades
    self:drawTankUpgradeMenu(player)

    -- NEW: Draw the Minimap
    self:drawMinimap(player)
end

function UIManager:drawTankUpgradeMenu(player)
    local x, y = 20, 20
    local i = 0
    for _, class in pairs(Classes) do
        -- Show if level is met and it's not the current tank
        if player.level >= class.level and player.tankName ~= class.name then
            -- Check if this class is a logical "next step" (optional logic here)
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", x, y + (i * 55), 140, 50, 4)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(class.name, x, y + (i * 55) + 18, 140, "center")
            i = i + 1
        end
    end
end

function UIManager:drawStatMenu(player)
    local x, y = 20, love.graphics.getHeight() - 250
    local width, height = 200, 25

    love.graphics.printf("Points: " .. player.statPoints, x, y - 25, width, "left")

    for i, stat in ipairs(self.statOptions) do
        local rectY = y + (i - 1) * (height + 5)
        
        -- Background bar
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", x, rectY, width, height, 4)

        -- Progress bar (how many points invested)
        local level = player.stats[stat.id]
        love.graphics.setColor(stat.color)

        if level > 0 then
            love.graphics.rectangle("fill", x, rectY, (width / 8) * level, height, 4)
        end

        -- Text label
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(stat.name .. " ["..level.."]", x + 5, rectY + 4, width, "left")
    end
end

function UIManager:drawMenuOverlay()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("DIEP.IO (Love2D Edition)", 0, h/2 - 80, w, "center")
end

function UIManager:mousepressed(x, y, button)
    local state = self.game.state
    if self.menus[state] then
        for _, element in pairs(self.menus[state]) do
            if element.mousepressed then
                element:mousepressed(x, y, button)
            end
        end
    end

    local player = self.game.player
    if self.game.state == "PLAYING" and player.statPoints > 0 then
        local startX, startY = 20, love.graphics.getHeight() - 250
        local width, height = 200, 25

        for i, stat in ipairs(self.statOptions) do
            local rectY = startY + (i - 1) * (height + 5)
            
            -- Check if mouse is within this specific stat bar
            if x >= startX and x <= startX + width and y >= rectY and y <= rectY + height then
                if player.stats[stat.id] < 8 then -- Max level 8
                    player.stats[stat.id] = player.stats[stat.id] + 1
                    player.statPoints = player.statPoints - 1
                    
                    -- Apply the stat effect immediately
                    self:applyStatBoost(player, stat.id)
                end
                break
            end
        end
    end
    if self.game.state == "PLAYING" then
        local ux, uy = 20, 20
        local i = 0
        for _, class in pairs(Classes) do
            if player.level >= class.level and player.tankName ~= class.name then
                local rectY = uy + (i * 55)
                if x >= ux and x <= ux + 140 and y >= rectY and y <= rectY + 50 then
                    self:upgradeTank(player, class)
                    break
                end
                i = i + 1
            end
        end
    end
end

function UIManager:upgradeTank(player, class)
    player.tankName = class.name
    player.barrels = {}
    for _, b in ipairs(class.barrels) do
        -- Passing the whole 'b' table as the config parameter
        table.insert(player.barrels, self.game.res.Barrel:new(
            player, 
            b.offset, 
            b.delay, 
            b.type, 
            b -- This contains isTrapezoid, tipWidth, lengthMult, etc.
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

return UIManager