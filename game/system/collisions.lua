-- game/system/collisions.lua
local Collisions = {}

-- Tunable strength for the "diep.io" feel
local PUSH_STRENGTH = 50

-- 1. Shape vs Shape (Soft Push)
function Collisions.checkShapeCollisions(shapes, dt)
    for i = 1, #shapes do
        for j = i + 1, #shapes do
            local s1, s2 = shapes[i], shapes[j]
            local dx, dy = s2.x - s1.x, s2.y - s1.y
            local distance = math.sqrt(dx*dx + dy*dy)
            local minDistance = s1:getRadius() + s2:getRadius()

            if distance < minDistance and distance > 0 then
                local nx, ny = dx / distance, dy / distance
                
                -- thang one
                s1.vx = s1.vx - nx * PUSH_STRENGTH * math.abs(s2.vx) / (s1.size / 5) * dt
                s1.vy = s1.vy - ny * PUSH_STRENGTH * math.abs(s2.vy) / (s1.size / 5) * dt
                -- thang two
                s2.vx = s2.vx + nx * PUSH_STRENGTH * math.abs(s1.vx) / (s2.size / 5) * dt
                s2.vy = s2.vy + ny * PUSH_STRENGTH * math.abs(s1.vy) / (s2.size / 5) * dt
            end
        end
    end
end

-- 2. Drone vs Drone (Repulsion)
function Collisions.checkDroneCollisions(bullets, dt)
    for i = 1, #bullets do
        local d1 = bullets[i]
        if d1.type == "drone" then
            for j = i + 1, #bullets do
                local d2 = bullets[j]
                if d2.type == "drone" then
                    local dx, dy = d2.x - d1.x, d2.y - d1.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    local min = d1.radius + d2.radius
                    
                    if dist < min and dist > 0 then
                        local nx, ny = dx / dist, dy / dist
                        
                        -- thang one
                        d1.vx = d1.vx - nx * (PUSH_STRENGTH / 2) * math.abs(d2.vx) / (d1.radius / 5) * dt
                        d1.vy = d1.vy - ny * (PUSH_STRENGTH / 2) * math.abs(d2.vy) / (d1.radius / 5) * dt
                        -- thang two
                        d2.vx = d2.vx + nx * (PUSH_STRENGTH / 2) * math.abs(d1.vx) / (d2.radius / 5) * dt
                        d2.vy = d2.vy + ny * (PUSH_STRENGTH / 2) * math.abs(d1.vy) / (d2.radius / 5) * dt
                    end
                end
            end
        end
    end
end

-- 3. Bullet/Drone vs Shape
function Collisions.checkBulletShapeCollisions(bullets, shapes, game, dt)
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        for j = #shapes, 1, -1 do
            local s = shapes[j]
            local dx, dy = b.x - s.x, b.y - s.y
            local dist = math.sqrt(dx*dx + dy*dy)
            local min = b.radius + s:getRadius()

            if dist < min then
                -- Calculate Normal Vector for the push
                local nx, ny = dx / dist, dy / dist
                
                -- Apply physical impact: The bullet pushes the shape
                s.vx = s.vx - nx * PUSH_STRENGTH * math.abs(b.vx) / (s.size / 5) * dt
                s.vy = s.vy - ny * PUSH_STRENGTH * math.abs(b.vy) / (s.size / 5) * dt
                
                -- The shape pushes the bullet back (Recoil)
                b.vx = b.vx + nx * PUSH_STRENGTH * math.abs(s.vx) / (b.radius / 5) * dt
                b.vy = b.vy + ny * PUSH_STRENGTH * math.abs(s.vy) / (b.radius / 5) * dt

                -- Logic for health and penetration
                b.penetration = b.penetration - 1
                s.health = s.health - b.damage
                s.hitTimer = 0.2

                if b.penetration <= 0 then b.isdead = true end
                
                if s.health <= 0 then
                    b.player.xp = b.player.xp + (s.max_health * 2)
                    s.deathAnim = game.res.Animation:new(s)
                    table.insert(game.dyingObjects, s)
                    table.remove(shapes, j)
                end
                
                -- In diep.io, bullets "grind" through shapes. 
                -- We only 'break' if the bullet is destroyed.
                if b.isdead then break end 
            end
        end
    end
end

-- 4. Player vs Shape (Soft Push)
function Collisions.checkPlayerShapeCollisions(player, shapes, dt)
    for i = #shapes, 1, -1 do
        local s = shapes[i]
        local dx, dy = s.x - player.x, s.y - player.y
        local dist = math.sqrt(dx*dx + dy*dy)
        local min = player.radius + s:getRadius()

        if dist < min and dist > 0 then
            local nx, ny = dx / dist, dy / dist
            -- da player
            player.vx = player.vx - nx * PUSH_STRENGTH * math.abs(s.vx) / (player.radius / 5) * dt
            player.vy = player.vy - ny * PUSH_STRENGTH * math.abs(s.vy) / (player.radius / 5) * dt
            -- da thang
            s.vx = s.vx + nx * PUSH_STRENGTH * math.abs(player.vx) / (s.size / 5) * dt
            s.vy = s.vy + ny * PUSH_STRENGTH * math.abs(player.vy) / (s.size / 5) * dt

            -- Damage logic remains
            player.health = player.health - 0.5
            player.hitTimer, s.hitTimer = 0.2, 0.2
        end
    end
end

return Collisions