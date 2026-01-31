-- game/data/classes.lua
local Classes = {
    -- TIER 1
    Tank = {
        id = 1, name = "Tank", level = 1, fire_rate = 0.4,
        barrels = {{xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet"}},
        upgrades = {2, 3, 4, 5}
    },
    -- TIER 2
    MachineGun = {
        id = 2, name = "Machine Gun", level = 15, fire_rate = 0.25,
        barrels = {{xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", widthMult = 1, isTrapezoid = true, tipWidth = 1.3, spread = 0.25}},
        upgrades = {6, 12} -- Destroyer, Gunner
    },
    Sniper = {
        id = 3, name = "Sniper", level = 15, fire_rate = 0.6,
        barrels = {{xOffset = 0, yOffsetMult = 0.8, delay = 0, type = "bullet", lengthMult = 1.6, widthMult = 0.65, bulletSize = 0.8, spread = 0.01}},
        upgrades = {7, 13} -- Assassin, Overseer
    },
    FlankGuard = {
        id = 4, name = "Flank Guard", level = 15, fire_rate = 0.4,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet"},
            {xOffset = 0, yOffsetMult = 0.2, delay = 0, type = "bullet", angleOffset = math.pi}
        },
        upgrades = {8, 10}
    },
    Twin = {
        id = 5, name = "Twin", level = 15, fire_rate = 0.45,
        barrels = {
            {xOffset = -12, yOffsetMult = 0.4, delay = 0, type = "bullet"},
            {xOffset = 12,  yOffsetMult = 0.4, delay = 0.5, type = "bullet"}
        },
        upgrades = {9} -- Upgrades to Triple Shot
    },

    -- TIER 3
    Destroyer = {
        id = 6, name = "Destroyer", level = 30, fire_rate = 1.8,
        barrels = {{xOffset = 0, yOffsetMult = -0.2, lengthMult = 1.8, widthMult = 1.3, bulletSize = 2.5, recoilMult = 4.0}},
        upgrades = {14} -- Hybrid
    },
    Assassin = {
        id = 7, name = "Assassin", level = 30, fire_rate = 0.75,
        barrels = {{xOffset = 0, yOffsetMult = 1.0, lengthMult = 2.1, widthMult = 0.6, bulletSize = 0.8, spread = 0}},
        upgrades = {15} -- Ranger
    },
    TriAngle = {
        id = 8, name = "Tri-Angle", level = 30, fire_rate = 0.4,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet"}, 
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = math.pi - 0.5, recoilMult = 1.5},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = math.pi + 0.5, recoilMult = 1.5}
        },
        upgrades = {16} -- Booster
    },
    TripleShot = {
        id = 9, name = "Triple Shot", level = 30, fire_rate = 0.5,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet"},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = -math.pi/6},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = math.pi/6}
        },
        upgrades = {17} -- Penta Shot
    },
    QuadTank = {
        id = 10, name = "Quad Tank", level = 30, fire_rate = 0.45,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = 0},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = math.pi/2},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = math.pi},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = -math.pi/2}
        },
        upgrades = {11}
    },
    Gunner = {
        id = 12, name = "Gunner", level = 30, fire_rate = 0.55,
        barrels = {
            {xOffset = -10, yOffsetMult = 0.2, delay = 0, type = "bullet", widthMult = 0.5, bulletSize = 0.6},
            {xOffset = 10, yOffsetMult = 0.2, delay = 0.5, type = "bullet", widthMult = 0.5, bulletSize = 0.6},
            {xOffset = -5, yOffsetMult = 0.4, delay = 0.25, type = "bullet", widthMult = 0.5, bulletSize = 0.6},
            {xOffset = 5, yOffsetMult = 0.4, delay = 0.75, type = "bullet", widthMult = 0.5, bulletSize = 0.6}
        },
        upgrades = {}
    },
    Overseer = {
        id = 13, name = "Overseer", level = 30, fire_rate = 2.0,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = math.pi/2, type = "drone", isTrapezoid = true, tipWidth = 1.5},
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = -math.pi/2, type = "drone", isTrapezoid = true, tipWidth = 1.5}
        },
        upgrades = {18, 19, 20} -- Overlord, Manager, Necromancer
    },

    -- TIER 4
    OctoTank = {
        id = 11, name = "Octo Tank", level = 45, fire_rate = 0.5,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = 0},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = math.pi/4},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = math.pi/2},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = 3*math.pi/4},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = math.pi},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = -3*math.pi/4},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = -math.pi/2},
            {xOffset = 0, yOffsetMult = 0.4, delay = 0, type = "bullet", angleOffset = -math.pi/4}
        },
        upgrades = {}
    },
    Hybrid = {
        id = 14, name = "Hybrid", level = 45, fire_rate = 1.8,
        barrels = {
            {xOffset = 0, yOffsetMult = -0.2, lengthMult = 1.8, widthMult = 1.3, bulletSize = 2.5, recoilMult = 4.0, type = "bullet"},
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = math.pi, type = "drone", isTrapezoid = true, tipWidth = 1.5} -- Automatic drone spawner
        },
        upgrades = {}
    },
    Ranger = {
        id = 15, name = "Ranger", level = 45, fire_rate = 0.8,
        barrels = {{xOffset = 0, yOffsetMult = 1.2, lengthMult = 2.5, widthMult = 0.6, bulletSize = 0.8, spread = 0}},
        upgrades = {}
    },
    Booster = {
        id = 16, name = "Booster", level = 45, fire_rate = 0.4,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.4, type = "bullet"}, -- Front
            {xOffset = 0, yOffsetMult = 0.4, angleOffset = math.pi - 0.4, recoilMult = 1.5}, -- Back Wing 1
            {xOffset = 0, yOffsetMult = 0.4, angleOffset = math.pi + 0.4, recoilMult = 1.5}, -- Back Wing 2
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = math.pi - 0.7, recoilMult = 1.2}, -- Outer Wing 1
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = math.pi + 0.7, recoilMult = 1.2}  -- Outer Wing 2
        },
        upgrades = {}
    },
    PentaShot = {
        id = 17, name = "Penta Shot", level = 45, fire_rate = 0.5,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.4, angleOffset = 0},
            {xOffset = 0, yOffsetMult = 0.4, angleOffset = -math.pi/8},
            {xOffset = 0, yOffsetMult = 0.4, angleOffset = math.pi/8},
            {xOffset = 0, yOffsetMult = 0.4, angleOffset = -math.pi/4},
            {xOffset = 0, yOffsetMult = 0.4, angleOffset = math.pi/4}
        },
        upgrades = {}
    },
    Overlord = {
        id = 18, name = "Overlord", level = 45, fire_rate = 2.0,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = 0, type = "drone", isTrapezoid = true, tipWidth = 1.5},
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = math.pi/2, type = "drone", isTrapezoid = true, tipWidth = 1.5},
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = math.pi, type = "drone", isTrapezoid = true, tipWidth = 1.5},
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = -math.pi/2, type = "drone", isTrapezoid = true, tipWidth = 1.5}
        },
        upgrades = {}
    },
    Manager = {
        id = 19, name = "Manager", level = 45, fire_rate = 2.5,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.4, type = "drone", isTrapezoid = true, tipWidth = 1.5}
        },
        canInvisibility = true,
        upgrades = {}
    },
    Necromancer = {
        id = 20, name = "Necromancer", level = 45, fire_rate = 0.5,
        barrels = {
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = math.pi/2, type = "drone", isTrapezoid = true, tipWidth = 1.5, manualFire = false},
            {xOffset = 0, yOffsetMult = 0.3, angleOffset = -math.pi/2, type = "drone", isTrapezoid = true, tipWidth = 1.5, manualFire = false}
        },
        maxDrones = 32,
        droneType = "square",
        upgrades = {}
    }
}

return Classes