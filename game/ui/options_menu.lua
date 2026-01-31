-- game/ui/options_menu.lua
local OptionsMenu = {}

function OptionsMenu.get(game)
    local screenW, screenH = love.graphics.getDimensions()
    return {
        backButton = game.res.Button:new("BACK", screenW / 2 - 100, screenH - 100, 200, 50, function()
            game.state = "MENU"
        end)
    }
end

function OptionsMenu.draw(game)
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SETTINGS", 0, 100, w, "center")
    love.graphics.printf("Style:", w/2 - 150, 205, 100, "left")
    
    local styles = {"New", "Old"}
    for i, s in ipairs(styles) do
        local bx, by = w/2 - 50 + (i-1) * 110, 200
        
        if game.style == s then
            love.graphics.setColor(0, 0.7, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.3)
        end
        
        -- Diep style selection box
        love.graphics.rectangle("fill", bx, by, 100, 30, 4)
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.rectangle("fill", bx, by + 20, 100, 10) -- shadow
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(s, bx, by + 7, 100, "center")
    end
end

return OptionsMenu