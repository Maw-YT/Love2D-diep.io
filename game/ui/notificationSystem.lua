local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

local function drawOutlinedCenteredText(text, x, y, width, alpha)
    -- Draw a lighter black outline first (4 directions), then main text.
    local outlineAlpha = (alpha or 1) * 0.75
    love.graphics.setColor(0, 0, 0, outlineAlpha)
    love.graphics.printf(text, x - 1, y, width, "center")
    love.graphics.printf(text, x + 1, y, width, "center")
    love.graphics.printf(text, x, y - 1, width, "center")
    love.graphics.printf(text, x, y + 1, width, "center")
end

function NotificationSystem:new()
    local self = setmetatable({}, NotificationSystem)
    self.notifications = {} -- List of active notifications
    self.maxNotifications = 5 -- Maximum notifications to show at once
    self.notificationHeight = 30 -- Height of each notification box
    self.padding = 5 -- Padding between notifications
    self.horizontalPadding = 10 -- Horizontal padding inside the box (text margin)
    self.displayDuration = 4 -- How long each notification stays (seconds)
    self.slideDuration = 0.3 -- Duration of slide-in animation (seconds)
    self.fadeDuration = 0.5 -- Duration of fade-out animation (seconds)
    
    -- Colors
    self.bgColor = {1, 1, 0.2, 0.9} -- Bright yellow background
    self.textColor = {1, 1, 1, 1} -- White text
    
    return self
end

function NotificationSystem:addNotification(text, type)
    -- Calculate width based on text
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local notificationWidth = textWidth + (self.horizontalPadding * 2)
    
    local notification = {
        text = text,
        type = type or "info", -- "killed" or "killed_by"
        age = 0, -- How long this notification has been active
        slideProgress = 0, -- 0 to 1 for slide-in animation
        yOffset = 0, -- Current Y offset for stacking
        targetYOffset = 0, -- Target Y offset (smooth transition)
        width = notificationWidth, -- Width based on text
    }
    
    -- Insert at the beginning (top of stack)
    table.insert(self.notifications, 1, notification)
    
    -- Remove oldest if we exceed max
    if #self.notifications > self.maxNotifications then
        table.remove(self.notifications)
    end
    
    -- Recalculate target Y offsets for all notifications
    self:recalculateOffsets()
end

function NotificationSystem:recalculateOffsets()
    for i, notif in ipairs(self.notifications) do
        notif.targetYOffset = (i - 1) * (self.notificationHeight + self.padding)
    end
end

function NotificationSystem:update(dt)
    for i = #self.notifications, 1, -1 do
        local notif = self.notifications[i]
        notif.age = notif.age + dt
        
        -- Slide-in animation
        if notif.slideProgress < 1 then
            notif.slideProgress = math.min(1, notif.slideProgress + dt / self.slideDuration)
        end
        
        -- Smooth Y offset transition
        local diff = notif.targetYOffset - notif.yOffset
        notif.yOffset = notif.yOffset + diff * 10 * dt
        
        -- Remove old notifications
        if notif.age > self.displayDuration + self.fadeDuration then
            table.remove(self.notifications, i)
        end
    end
    
    -- Recalculate offsets if any were removed
    self:recalculateOffsets()
end

function NotificationSystem:draw()
    local screenW = love.graphics.getWidth()
    local startY = 20 -- Start 20 pixels from top
    
    for i, notif in ipairs(self.notifications) do
        -- Calculate alpha for fade out
        local alpha = 1
        if notif.age > self.displayDuration then
            local fadeProgress = (notif.age - self.displayDuration) / self.fadeDuration
            alpha = math.max(0, 1 - fadeProgress)
        end
        
        -- Calculate slide-in offset (start from above screen)
        local slideOffset = (1 - notif.slideProgress) * -50
        
        -- Center the notification horizontally based on its width
        local x = (screenW - notif.width) / 2
        local y = startY + notif.yOffset + slideOffset
        
        -- Draw background (less rounded corners - radius 2 instead of 5)
        love.graphics.setColor(self.bgColor[1], self.bgColor[2], self.bgColor[3], self.bgColor[4] * alpha)
        love.graphics.rectangle("fill", x, y, notif.width, self.notificationHeight, 2, 2)
        
        -- Draw text outline + text
        drawOutlinedCenteredText(notif.text, x, y + 8, notif.width, self.textColor[4] * alpha)
        love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.textColor[4] * alpha)
        love.graphics.printf(notif.text, x, y + 8, notif.width, "center")
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Helper methods for specific notification types
function NotificationSystem:notifyKilled(botName)
    self:addNotification("You killed " .. botName .. ".", "killed")
end

function NotificationSystem:notifyKilledBy(botName)
    self:addNotification("You were killed by " .. botName .. ".", "killed_by")
end

function NotificationSystem:notifyBossSpawned()
    self:addNotification("A boss has spawned in the arena!", "boss_spawn")
end

function NotificationSystem:notifyAutoFire(enabled)
    if enabled then
        self:addNotification("Auto Fire: ON", "toggle")
    else
        self:addNotification("Auto Fire: OFF", "toggle")
    end
end

function NotificationSystem:notifyAutoSpin(enabled)
    if enabled then
        self:addNotification("Auto Spin: ON", "toggle")
    else
        self:addNotification("Auto Spin: OFF", "toggle")
    end
end

return NotificationSystem