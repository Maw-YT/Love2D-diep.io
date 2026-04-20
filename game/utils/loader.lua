-- game/system/loader.lua
local loader = {}

function loader.loadAll()
    local resources = {}

    -- Entities
    resources.Player    = require "game.entities.tank.player"
    resources.Bot       = require "game.entities.tank.bot"
    resources.Boss      = require "game.entities.boss"
    resources.Bullet    = require "game.entities.projectiles.bullet"
    resources.Shape     = require "game.entities.shape"
    resources.Barrel    = require "game.entities.tank.barrel"
    resources.Drone     = require "game.entities.projectiles.drone"
    resources.Trap      = require "game.entities.projectiles.trap"
    resources.FactoryDrone = require "game.entities.projectiles.factoryDrone"
    resources.Turret    = require "game.entities.tank.turret"

    -- Systems
    resources.Camera      = require "game.system.camera"
    resources.Arena       = require "game.world.arena"
    resources.ArenaFactory = require "game.world.arenaFactory"
    resources.Animation   = require "game.components.animation"
    resources.Button      = require "game.ui.button"
    resources.HealthBar   = require "game.components.healthBar"
    resources.XPBar       = require "game.ui.xpBar"
    resources.Leaderboard = require "game.ui.leaderboard"
    resources.Physics     = require "game.system.physics"
    resources.CollisionManager = require "game.system.collisionManager"
    resources.DeathManager= require "game.system.deathManager"
    resources.UIManager   = require "game.system.uiManager"
    resources.NotificationSystem = require "game.ui.notificationSystem"

    return resources
end

return loader