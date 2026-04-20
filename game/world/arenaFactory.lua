local FFAArena = require "game.world.arenas.ffaArena"
local SandboxArena = require "game.world.arenas.sandboxArena"
local TwoTeamsArena = require "game.world.arenas.twoTeamsArena"

local ArenaFactory = {}

function ArenaFactory.create(gamemode, width, height, player)
    if gamemode == "Sandbox" then
        return SandboxArena:new(width, height, player)
    elseif gamemode == "TwoTeams" then
        return TwoTeamsArena:new(width, height, player)
    end
    return FFAArena:new(width, height, player)
end

return ArenaFactory
