local Arena = require "game.world.arena"

local FFAArena = setmetatable({}, { __index = Arena })
FFAArena.__index = FFAArena

function FFAArena:new(w, h, player)
    local self = Arena:new(w, h, player)
    setmetatable(self, FFAArena)
    self.gamemode = "FFA"
    self.maxBots = 199
    self.maxShapes = 4000
    return self
end

return FFAArena
