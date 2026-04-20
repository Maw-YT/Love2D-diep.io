-- game/entities/projectiles/trap.lua
local EntityBase = require "game.native.entityBase"
local Trap = setmetatable({}, { __index = EntityBase })
Trap.__index = Trap

local Physics = require "game.system.physics"

function Trap:new(player, x, y, vx, vy)
    local self = EntityBase:new({
        type = "trap",
        team = (player and player.team) or player,
        owner = player,
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        radius = (player.radius * 1.0) / 2,
        angle = 0,
    })
    setmetatable(self, Trap)
    self.player = player
    self.color = player.color
    self.outline_color = player.outline_color
    self.damage = 2.5
    self.penetration = 3
    self.lifetime = 10.0
    self.age = 0
    return self
end

function Trap:update(dt)
    self.age = self.age + dt
    
    if self.age >= self.lifetime and not self.hasExploded then
        self:setDead(true)
    end

    Physics.applyPhysics(self, dt)
end

function Trap:draw(alpha, style)
    local a = alpha or 1
    
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    
    local angle = math.atan2(self.vy, self.vx)
    love.graphics.rotate(angle)
    
    local outerRadius = self.radius
    local innerRadius = self.radius * 0.4
    local vertices = {}
    
    for i = 0, 5 do
        local vertexAngle = (i * math.pi / 3) - (math.pi / 2)
        local radius = (i % 2 == 0) and outerRadius or innerRadius
        table.insert(vertices, math.cos(vertexAngle) * radius)
        table.insert(vertices, math.sin(vertexAngle) * radius)
    end
    
    love.graphics.setLineJoin("bevel")
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], a)
    love.graphics.polygon("fill", vertices)
    
    love.graphics.setLineWidth(2)
    if style == "New" then
        love.graphics.setColor(self.outline_color[1], self.outline_color[2], self.outline_color[3], a)
    elseif style == "Old" then
        love.graphics.setColor(0.3, 0.3, 0.3, a)
    end
    love.graphics.polygon("line", vertices)
    love.graphics.setLineJoin("miter")
    love.graphics.setLineWidth(1)
    
    love.graphics.pop()
end

return Trap
