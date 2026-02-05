-- game/system/arena.lua
local Arena = {}
Arena.__index = Arena

local loader = require "game.utils.loader"

function Arena:new(w, h, player)
    local self = setmetatable({}, Arena)
    self.width = w
    self.height = h
    self.padding = 1500
    self.player = player or nil
    self.shapes = {} -- Shapes now live here!
    self.res = loader.loadAll()

    -- Added a constant for the maximum population
    self.maxShapes = 4000
    return self
end

-- New function to maintain the shape population
function Arena:update(dt)
    -- Check if we are below the limit
    if #self.shapes < self.maxShapes then
        -- Calculate how many need to be spawned
        local needed = self.maxShapes - #self.shapes
        
        -- You can spawn them all at once, or limit it per frame 
        -- to prevent a performance spike (e.g., spawn 5 per frame)
        local spawnCount = math.min(needed, 5) 
        
        for i = 1, spawnCount do
            table.insert(self.shapes, self.res.Shape:newRandom(self))
        end
    end
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

    local nestSize = self.width * 0.15
    love.graphics.setColor(0.5, 0.5, 0.9, 0.25) -- Purple tint
    love.graphics.rectangle("fill", 
        (self.width / 2) - (nestSize / 2), 
        (self.height / 2) - (nestSize / 2), 
        nestSize, 
        nestSize
    )
    
    -- Light grid
    love.graphics.setColor(0, 0, 0, 0.05) -- ALMOST INVISALBE
    local step = 25
    -- Vertical lines
    for x = -self.padding, self.width + self.padding, step do
        love.graphics.line(x, -self.padding, x, self.height + self.padding)
    end
    -- Horizontal lines
    for y = -self.padding, self.height + self.padding, step do
        love.graphics.line(-self.padding, y, self.width + self.padding, y)
    end

    love.graphics.setLineWidth(1)
end

function Arena:spawnInitialShapes(count)
    for i = 1, count do
        table.insert(self.shapes, self.res.Shape:newRandom(self))
    end
end

-- Shape Drawing with Culling
function Arena:drawShapes(alpha, style, camera)  
    -- Calculate viewport bounds with padding for shapes partially visible  
    local screenW = love.graphics.getWidth()  
    local screenH = love.graphics.getHeight()  
    local padding = 100 -- Extra space for shapes near edges  
      
    local minX = camera.x - padding  
    local maxX = camera.x + (screenW / camera.scale) + padding  
    local minY = camera.y - padding  
    local maxY = camera.y + (screenH / camera.scale) + padding  
    for _, s in ipairs(self.shapes) do  
        -- Only draw if shape is within viewport  
        if s.x + s.size >= minX and s.x - s.size <= maxX and  
           s.y + s.size >= minY and s.y - s.size <= maxY then  
            s:draw(alpha, style)  
        end  
    end  
end

function Arena:updateShapes(dt, camera)  
    -- Calculate viewport bounds with padding for shapes partially visible  
    local screenW = love.graphics.getWidth()  
    local screenH = love.graphics.getHeight()  
    local padding = 100 -- Extra space for shapes near edges  
      
    local minX = camera.x - padding  
    local maxX = camera.x + (screenW / camera.scale) + padding
    local minY = camera.y - padding  
    local maxY = camera.y + (screenH / camera.scale) + padding
    for _, s in ipairs(self.shapes) do  
        s:update(dt, self)  
    end  
end

return Arena