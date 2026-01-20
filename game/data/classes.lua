-- game/data/classes.lua
local Classes = {
    Tank = {
        name = "Tank",
        level = 1,
        barrels = {
            {offset = 0, delay = 0.0, type = "bullet"}
        }
    },
    MachineGun = {
        name = "Machine Gun",
        level = 15,
        barrels = {
            -- Setting isTrapezoid = true and a larger tipWidth
            {offset = 0, delay = 0.0, type = "bullet", isTrapezoid = true, tipWidth = 1.4} 
        }
    },
    Sniper = {
        name = "Sniper",
        level = 15,
        barrels = {
            -- Snipers usually have longer, thinner barrels
            {offset = 0, delay = 0.0, type = "bullet", lengthMult = 1.5, widthMult = 0.6}
        }
    }
}

return Classes