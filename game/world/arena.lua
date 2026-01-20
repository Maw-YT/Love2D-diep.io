-- game/system/arena.lua
local Arena = {}
Arena.__index = Arena

local loader = require "game.utils.loader"

function Arena:new(w, h)
    local self = setmetatable({}, Arena)
    self.width = w
    self.height = h
    self.padding = 1500
    self.shapes = {} -- Shapes now live here!
    self.res = loader.loadAll()
    return self
end

function Arena:drawBackground()
    -- 1. Draw a dark background first (no mans land)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("fill", 
        -self.padding, 
        -self.padding, 
        self.width + (self.padding * 2), 
        self.height + (self.padding * 2)
    )

    -- Light background
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    -- In your arena drawing code:
    local nestSize = self.width * 0.15
    love.graphics.setColor(0.5, 0.5, 0.9, 0.25) -- Very faint gray
    love.graphics.rectangle("fill", 
        (self.width / 2) - (nestSize / 2), 
        (self.height / 2) - (nestSize / 2), 
        nestSize, 
        nestSize
    )
    
    -- Light grid
    love.graphics.setColor(0, 0, 0, 0.1)
    local step = 25
    -- Vertical lines
    for x = -self.padding, self.width + self.padding, step do
        love.graphics.line(x, -self.padding, x, self.height + self.padding)
    end
    -- Horizontal lines
    for y = -self.padding, self.height + self.padding, step do
        love.graphics.line(-self.padding, y, self.width + self.padding, y)
    end

    -- Border outline
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 0, 0, self.width, self.height)

    love.graphics.setLineWidth(1)
end

function Arena:spawnInitialShapes(count)
    for i = 1, count do
        table.insert(self.shapes, self.res.Shape:newRandom(self))
    end
end

-- Update your draw method to handle the shapes locally
function Arena:drawShapes(style)
    for _, s in ipairs(self.shapes) do
        s:draw(1, style)
    end
end

return Arena