-- game/system/loader.lua
local loader = {}

function loader.loadAll()
    local resources = {}

    -- Entities
    resources.Player    = require "game.entities.tank.player"
    resources.Bullet    = require "game.entities.tank.bullet"
    resources.Shape     = require "game.entities.shape"
    resources.Barrel    = require "game.entities.tank.barrel"
    resources.Drone     = require "game.entities.tank.drone"

    -- Systems
    resources.Camera    = require "game.system.camera"
    resources.Arena     = require "game.world.arena"
    resources.Animation = require "game.components.animation"
    resources.Button    = require "game.ui.button"
    resources.HealthBar = require "game.components.healthBar"
    resources.XPBar     = require "game.ui.xpBar"
    resources.Collisions = require "game.system.collisions"
    resources.CollisionManager = require "game.system.collisionManager"
    resources.DeathManager = require "game.system.deathManager"
    resources.UIManager = require "game.system.uiManager"

    return resources
end

return loader