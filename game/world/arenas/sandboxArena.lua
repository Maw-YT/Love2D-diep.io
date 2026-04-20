local Arena = require "game.world.arena"

local SandboxArena = setmetatable({}, { __index = Arena })
SandboxArena.__index = SandboxArena

function SandboxArena:new(w, h, player)
    local self = Arena:new(w, h, player)
    setmetatable(self, SandboxArena)
    self.gamemode = "Sandbox"
    self.maxBots = 0
    self.maxShapes = 4000
    return self
end

return SandboxArena
