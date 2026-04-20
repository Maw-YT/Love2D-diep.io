-- game/native/fieldGroups.lua
-- DiepCustom-style field groups: logical bundles over existing entity fields (Native/FieldGroups.ts).

local FieldGroups = {}

local function bind(entity, keyMap)
    return setmetatable({}, {
        __index = function(_, k)
            local ek = keyMap[k]
            if ek then return entity[ek] end
            return entity[k]
        end,
        __newindex = function(_, k, v)
            local ek = keyMap[k]
            if ek then entity[ek] = v else entity[k] = v end
        end,
    })
end

function FieldGroups.attachPositionGroup(entity)
    entity.positionData = { values = bind(entity, {}) }
end

function FieldGroups.attachPhysicsGroup(entity)
    entity.physicsData = {
        values = setmetatable({}, {
            __index = function(_, k)
                if k == "size" then
                    if entity.getRadius then return entity:getRadius() end
                    return entity.radius or entity.size or 20
                end
                if k == "pushFactor" then return entity.pushFactor end
                if k == "absorptionFactor" or k == "absorbtionFactor" then
                    return entity.absorptionFactor
                end
                if k == "sides" then return entity.sides end
                if k == "flags" then return entity.physicsFlags or 0 end
                return entity[k]
            end,
            __newindex = function(_, k, v)
                if k == "pushFactor" then entity.pushFactor = v end
                if k == "absorptionFactor" or k == "absorbtionFactor" then
                    entity.absorptionFactor = v
                end
                if k == "sides" then entity.sides = v end
                if k == "flags" then entity.physicsFlags = v end
                if k == "size" and entity.radius ~= nil then entity.radius = v end
            end,
        }),
    }
end

function FieldGroups.attachHealthGroup(entity)
    entity.healthData = {
        values = bind(entity, { maxHealth = "max_health" }),
    }
end

function FieldGroups.attachRelationsGroup(entity)
    if not entity.relationsData then
        entity.relationsData = { values = { team = nil, owner = nil } }
    end
end

function FieldGroups.attachStyleGroup(entity)
    if entity.invisAlpha ~= nil then
        entity.styleData = { values = bind(entity, { opacity = "invisAlpha" }) }
    else
        if entity.styleOpacity == nil then entity.styleOpacity = 1 end
        entity.styleData = { values = bind(entity, { opacity = "styleOpacity" }) }
    end
end

return FieldGroups
