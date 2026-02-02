--[[
 * Mogster Control - Main Entry Point
 * 
 * Dashboard widget for controlling Mogster off-road vehicle
 * Features: Lights, Indicators, Sound, Battery Status
 * 
 * License: MIT
--]]

local name = "Mogster Control"

-- State variables
local state = {
    lightsOn = false,
    indicatorLeft = false,
    indicatorRight = false,
    hornActive = false,
    batteryVoltage = 12.6,
    batteryPercent = 75
}

-- Helper function to render control button
local function renderControlButton(x, y, w, h, label, active, activeColor)
    local isDarkMode = lcd.darkMode()
    
    -- Button background
    if active then
        lcd.color(activeColor or lcd.RGB(0, 200, 0))
    else
        lcd.color(isDarkMode and lcd.RGB(40, 40, 40) or lcd.RGB(200, 200, 200))
    end
    lcd.drawFilledRectangle(x, y, w, h)
    
    -- Button border
    lcd.color(isDarkMode and lcd.RGB(255, 255, 255) or lcd.RGB(0, 0, 0))
    lcd.drawRectangle(x, y, w, h, 3)
    
    -- Button text
    local textColor = active and lcd.RGB(255, 255, 255) or (isDarkMode and lcd.RGB(200, 200, 200) or lcd.RGB(60, 60, 60))
    lcd.color(textColor)
    lcd.font(FONT_XL)
    local tw, th = lcd.getTextSize(label)
    lcd.drawText(x + (w - tw) / 2, y + (h - th) / 2, label)
end

-- Helper function to render battery status
local function renderBatteryStatus(x, y, w, h, voltage, percent)
    local isDarkMode = lcd.darkMode()
    
    -- Background
    lcd.color(isDarkMode and lcd.RGB(30, 30, 30) or lcd.RGB(220, 220, 220))
    lcd.drawFilledRectangle(x, y, w, h)
    
    -- Border
    lcd.color(isDarkMode and lcd.RGB(255, 255, 255) or lcd.RGB(0, 0, 0))
    lcd.drawRectangle(x, y, w, h, 2)
    
    -- Battery icon frame
    local battX = x + 20
    local battY = y + h / 2 - 25
    local battW = 100
    local battH = 50
    
    lcd.color(isDarkMode and lcd.RGB(255, 255, 255) or lcd.RGB(0, 0, 0))
    lcd.drawRectangle(battX, battY, battW, battH, 3)
    
    -- Battery cap
    local capW = 8
    local capH = 30
    lcd.drawFilledRectangle(battX + battW, battY + (battH - capH) / 2, capW, capH)
    
    -- Battery fill
    local fillW = (battW - 10) * (percent / 100)
    
    if percent > 50 then
        lcd.color(lcd.RGB(0, 255, 0))
    elseif percent > 20 then
        lcd.color(lcd.RGB(255, 200, 0))
    else
        lcd.color(lcd.RGB(255, 0, 0))
    end
    lcd.drawFilledRectangle(battX + 5, battY + 5, fillW, battH - 10)
    
    -- Battery text
    lcd.color(isDarkMode and lcd.RGB(255, 255, 255) or lcd.RGB(0, 0, 0))
    lcd.font(FONT_XL)
    local battText = string.format("%d%%", percent)
    local tw, th = lcd.getTextSize(battText)
    lcd.drawText(battX + battW + 20, battY + (battH - th) / 2, battText)
    
    -- Voltage display
    local voltText = string.format("%.1fV", voltage)
    lcd.font(FONT_L)
    tw, th = lcd.getTextSize(voltText)
    lcd.drawText(battX + battW + 20, battY + battH / 2 + 10, voltText)
end

local function create(zone, options)
    return {
        zone = zone,
        options = options
    }
end

local function paint(widget)
    if not widget or not widget.zone then
        return
    end
    
    local zone = widget.zone
    local isDarkMode = lcd.darkMode()
    
    -- Clear background
    lcd.color(isDarkMode and lcd.RGB(20, 20, 20) or lcd.RGB(240, 240, 240))
    lcd.drawFilledRectangle(zone.x, zone.y, zone.w, zone.h)
    
    -- Title
    lcd.color(isDarkMode and lcd.RGB(255, 255, 255) or lcd.RGB(0, 0, 0))
    lcd.font(FONT_XXL)
    local title = "MOGSTER CONTROL"
    local tw, th = lcd.getTextSize(title)
    lcd.drawText(zone.x + (zone.w - tw) / 2, zone.y + 10, title)
    
    -- Calculate button layout
    local buttonY = zone.y + 80
    local buttonW = math.min(150, (zone.w - 100) / 4)
    local buttonH = 60
    local spacing = 20
    local totalWidth = buttonW * 4 + spacing * 3
    local startX = zone.x + (zone.w - totalWidth) / 2
    
    -- Draw control buttons
    renderControlButton(startX, buttonY, buttonW, buttonH, "LIGHTS", state.lightsOn, lcd.RGB(255, 200, 0))
    renderControlButton(startX + buttonW + spacing, buttonY, buttonW, buttonH, "◄ LEFT", state.indicatorLeft, lcd.RGB(255, 140, 0))
    renderControlButton(startX + (buttonW + spacing) * 2, buttonY, buttonW, buttonH, "RIGHT ►", state.indicatorRight, lcd.RGB(255, 140, 0))
    renderControlButton(startX + (buttonW + spacing) * 3, buttonY, buttonW, buttonH, "HORN", state.hornActive, lcd.RGB(200, 0, 0))
    
    -- Battery status
    local battY = buttonY + buttonH + 40
    local battW = zone.w - 100
    local battH = 80
    renderBatteryStatus(zone.x + 50, battY, battW, battH, state.batteryVoltage, state.batteryPercent)
end

local function event(widget, category, value, x, y)
    if not widget or not widget.zone then
        return false
    end
    
    -- Handle touch events
    if category == EVT_TOUCH_FIRST or category == EVT_TOUCH_TAP then
        local zone = widget.zone
        local buttonY = zone.y + 80
        local buttonW = math.min(150, (zone.w - 100) / 4)
        local buttonH = 60
        local spacing = 20
        local totalWidth = buttonW * 4 + spacing * 3
        local startX = zone.x + (zone.w - totalWidth) / 2
        
        -- Check button presses
        if y >= buttonY and y <= buttonY + buttonH then
            -- Lights button
            if x >= startX and x <= startX + buttonW then
                state.lightsOn = not state.lightsOn
                lcd.invalidate()
                return true
            -- Left indicator
            elseif x >= startX + buttonW + spacing and x <= startX + (buttonW + spacing) * 2 - spacing then
                state.indicatorLeft = not state.indicatorLeft
                if state.indicatorLeft then
                    state.indicatorRight = false
                end
                lcd.invalidate()
                return true
            -- Right indicator
            elseif x >= startX + (buttonW + spacing) * 2 and x <= startX + (buttonW + spacing) * 3 - spacing then
                state.indicatorRight = not state.indicatorRight
                if state.indicatorRight then
                    state.indicatorLeft = false
                end
                lcd.invalidate()
                return true
            -- Horn button
            elseif x >= startX + (buttonW + spacing) * 3 and x <= startX + (buttonW + spacing) * 4 then
                state.hornActive = not state.hornActive
                lcd.invalidate()
                return true
            end
        end
    end
    return false
end

-- Register the widget with Ethos
local function init()
    system.registerWidget({
        key = "mogster",
        name = name,
        create = create,
        paint = paint,
        event = event
    })
end

return {init = init}
