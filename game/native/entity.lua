-- game/native/entity.lua
-- Base entity tier (Native/Entity.ts).

local Entity = {}

function Entity.exists(e)
    return e ~= nil
end

return Entity
