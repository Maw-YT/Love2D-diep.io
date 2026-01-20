-- game/system/xpBar.lua
local XPBar = {}
XPBar.__index = XPBar

function XPBar:new()
    local self = setmetatable({}, XPBar)
    -- UI dimensions
    self.width = 400
    self.height = 20
    self.color = {1, 0.8, 0.2} 
    self.bg_color = {0.2, 0.2, 0.2, 0.8}
    
    -- NEW: Track visual progress separately for lerping
    self.visualXp = 0
    return self
end

function XPBar:draw(player, dt)
    -- If the player just leveled up, snap the visual bar back to 0 
    -- so it starts filling from the left again
    if player.xpBarReset then
        self.visualXp = 0
        player.xpBarReset = false
    end

    -- LERP LOGIC: Smoothly move visualXp toward the actual player.xp
    -- 10 is the speed of the animation; higher is faster.
    self.visualXp = self.visualXp + (player.xp - self.visualXp) * 10 * dt

    local screenW, screenH = love.graphics.getDimensions()
    local x = (screenW - self.width) / 2
    local y = screenH - 60
    
    -- Use visualXp for the fill ratio instead of player.xp
    local fillRatio = math.min(self.visualXp / player.xpNextLevel, 1)
    local fillWidth = self.width * fillRatio
    
    local levelText = "Level " .. player.level
    local xpText = math.floor(player.xp)

    -- 1. Draw Background
    love.graphics.setColor(self.bg_color)
    love.graphics.rectangle("fill", x, y, self.width, self.height, 4)

    -- 2. Draw Fill (using visual ratio)
    if self.visualXp > 0.1 then -- small buffer for the "cursor" fix
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", x, y, fillWidth, self.height, 12)
    end
    
    -- 3. Draw Outline
    love.graphics.setLineWidth(5)
    love.graphics.setColor(self.bg_color[1], self.bg_color[2], self.bg_color[3])
    love.graphics.rectangle("line", x, y, self.width, self.height, 4)
    love.graphics.setLineWidth(1)

    -- 4. Draw White text (Unfilled side)
    love.graphics.setScissor(x + fillWidth, y - 30, self.width - fillWidth, self.height + 40)
    love.graphics.setColor(0, 0, 0) 
    love.graphics.printf(levelText, x, y - 25, self.width, "center")
    love.graphics.setColor(1, 1, 1) 
    love.graphics.printf(xpText, x, y + 2, self.width, "center")
    love.graphics.setScissor()

    -- 5. Draw Black text (Filled side)
    love.graphics.setScissor(x, y - 30, fillWidth, self.height + 40)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(levelText, x, y - 25, self.width, "center")
    love.graphics.printf(xpText, x, y + 2, self.width, "center")
    love.graphics.setScissor()
end

return XPBar