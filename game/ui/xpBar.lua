-- game/system/xpBar.lua
local XPBar = {}
XPBar.__index = XPBar

function XPBar:new()
    local self = setmetatable({}, XPBar)
    self.width = 400
    self.height = 20
    self.color = {0.9, 0.8, 0.4} 
    self.bg_color = {0.2, 0.2, 0.2, 0.8}
    self.visualXp = 0
    return self
end

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

local white = {1, 1, 1}
local black = {0, 0, 0}

function XPBar:draw(player, dt)
    if player.xpBarReset then
        self.visualXp = 0
        player.xpBarReset = false
    end

    self.visualXp = self.visualXp + (player.xp - self.visualXp) * 10 * dt

    local screenW, screenH = love.graphics.getDimensions()
    local x = (screenW - self.width) / 2
    local y = screenH - 60
    
    local fillRatio = math.min(self.visualXp / player.xpNextLevel, 1)
    local fillWidth = self.width * fillRatio
    
    local levelText = "Lvl " .. player.level.. " ".. player.tankName
    local xpText =  "Score: ".. math.floor(player.xp)

    -- 1. Draw Background (Pill Shape)
    love.graphics.setColor(self.bg_color)
    love.graphics.rectangle("fill", x, y, self.width, self.height, 10)

    -- 2. Draw Fill (Pill Shape)
    if self.visualXp > 0.1 then
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", x, y, fillWidth, self.height, 10)
    end
    
    -- 3. Draw Outline
    love.graphics.setLineWidth(4)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", x, y, self.width, self.height, 10)

    -- 4. Draw "Level" Text (Always Black, above the bar)
    drawOutlinedText(xpText, x, y - 25, self.width, "center", white, black)

    -- 5. Draw XP/Score Text (White to Black transition inside the bar)
    love.graphics.setLineWidth(1)
    
    -- Draw Xptext
    love.graphics.setColor(1, 1, 1) 
    drawOutlinedText(levelText, x, y + 2, self.width, "center", white, black)
    --love.graphics.printf(xpText, x, y + 2, self.width, "center")
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset
end

return XPBar