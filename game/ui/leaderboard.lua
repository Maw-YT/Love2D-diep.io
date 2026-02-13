-- game/ui/leaderboard.lua
local Leaderboard = {}
Leaderboard.__index = Leaderboard

function Leaderboard:new()
    local self = setmetatable({}, Leaderboard)
    self.width = 220
    self.height = 280
    self.bgColor = {0.1, 0.1, 0.1, 0.7}
    self.borderColor = {0.4, 0.4, 0.4, 0.8}
    self.titleColor = {0.9, 0.9, 0.9}
    self.playerColor = {0.2, 0.8, 0.9}  -- Cyan for player
    self.botColor = {0.9, 0.4, 0.4}     -- Red for bots
    self.textColor = {0.9, 0.9, 0.9}
    return self
end

local titleFont = nil
local entryFont = nil

function Leaderboard:initFonts()
    if not titleFont then
        titleFont = love.graphics.newFont(16)
        entryFont = love.graphics.newFont(14)
    end
end

function Leaderboard:getTopTen(player, bots)
    local allEntities = {}
    
    -- Add player
    if player and not player.isDead then
        table.insert(allEntities, {
            name = player.name,
            level = player.level,
            score = player.score or 0,
            isPlayer = true
        })
    end
    
    -- Add bots
    for _, bot in ipairs(bots) do
        if bot.health > 0 and not bot.isDead then
            table.insert(allEntities, {
                name = bot.name,
                level = bot.level,
                score = bot.score or 0,
                isPlayer = false
            })
        end
    end
    
    -- Sort by score (descending)
    table.sort(allEntities, function(a, b) return a.score > b.score end)
    
    -- Return top 10
    local topTen = {}
    for i = 1, math.min(10, #allEntities) do
        allEntities[i].rank = i
        table.insert(topTen, allEntities[i])
    end
    
    return topTen
end

function Leaderboard:draw(player, bots)
    self:initFonts()
    
    local topTen = self:getTopTen(player, bots)
    if #topTen == 0 then return end
    
    local screenW = love.graphics.getWidth()
    local x = screenW - self.width - 20
    local y = 20
    local padding = 10
    local lineHeight = 22
    
    -- Calculate height based on entries
    local contentHeight = 35 + (#topTen * lineHeight)
    
    -- Draw background
    love.graphics.setColor(self.bgColor)
    love.graphics.rectangle("fill", x, y, self.width, contentHeight, 5)
    
    -- Draw border
    love.graphics.setColor(self.borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, self.width, contentHeight, 5)
    
    -- Draw title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(self.titleColor)
    love.graphics.printf("LEADERBOARD", x, y + padding, self.width, "center")
    
    -- Draw entries
    love.graphics.setFont(entryFont)
    local entryY = y + 35
    
    for _, entry in ipairs(topTen) do
        -- Rank number
        if entry.rank == 1 then
            love.graphics.setColor(1, 0.84, 0)  -- Gold
        elseif entry.rank == 2 then
            love.graphics.setColor(0.8, 0.8, 0.8)  -- Silver
        elseif entry.rank == 3 then
            love.graphics.setColor(0.8, 0.5, 0.3)  -- Bronze
        else
            love.graphics.setColor(0.6, 0.6, 0.6)  -- Gray
        end
        love.graphics.print(tostring(entry.rank) .. ".", x + padding, entryY)
        
        -- Name (with color coding)
        if entry.isPlayer then
            love.graphics.setColor(self.playerColor)
        else
            love.graphics.setColor(self.botColor)
        end
        local nameText = entry.name
        if #nameText > 12 then
            nameText = string.sub(nameText, 1, 12) .. ".."
        end
        love.graphics.print(nameText, x + padding + 25, entryY)
        
        -- Score
        love.graphics.setColor(self.textColor)
        local scoreText = tostring(math.floor(entry.score))
        local scoreWidth = entryFont:getWidth(scoreText)
        love.graphics.print(scoreText, x + self.width - padding - scoreWidth, entryY)
        
        entryY = entryY + lineHeight
    end
    
    -- Reset
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Leaderboard
