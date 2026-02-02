--[[
 * Mogster Control - Main Entry Point
 * 
 * Dashboard widget for controlling Mogster off-road vehicle
 * Features: Lights, Indicators, Sound, Battery Status
 * 
 * License: MIT
--]]

local name = "Mogster Control"

-- Load assets
local assets = {}
local function loadAssets()
    local basePath = "/scripts/mogster/assets/"
    assets.arrowLeft = lcd.loadBitmap(basePath .. "arrow_left.png")
end

-- State variables
local state = {
    lightsOn = false,
    indicatorLeft = false,
    indicatorRight = false,
    hornActive = false,
    button5 = false,
    button6 = false,
    button7 = false,
    button8 = false,
    batteryVoltage = 12.6,
    batteryPercent = 75,
    blinkState = false,
    lastBlinkTime = 0
}

-- Source for indicator control
local function getIndicatorValue()
    if state.indicatorLeft then
        return -1024  -- Full left
    elseif state.indicatorRight then
        return 1024   -- Full right
    else
        return 0      -- Center position
    end
end

-- Helper function to render control button with optional icon
local function renderControlButton(x, y, size, label, active, activeColor, icon, bitmap)
    local isDarkMode = lcd.darkMode()
    
    -- Button background
    if active then
        lcd.color(activeColor or lcd.RGB(0, 200, 0))
    else
        lcd.color(isDarkMode and lcd.RGB(40, 40, 40) or lcd.RGB(200, 200, 200))
    end
    lcd.drawFilledRectangle(x, y, size, size)
    
    -- Button border
    lcd.color(isDarkMode and lcd.RGB(255, 255, 255) or lcd.RGB(0, 0, 0))
    lcd.drawRectangle(x, y, size, size, 3)
    
    -- Draw bitmap if provided
    if bitmap then
        -- Scale bitmap to fit button with padding
        local padding = 10
        local bmpSize = size - (padding * 2)
        lcd.drawBitmap(x + padding, y + padding, bitmap, bmpSize, bmpSize)
    -- Draw text icon if provided
    elseif icon then
        local textColor = active and lcd.RGB(255, 255, 255) or (isDarkMode and lcd.RGB(200, 200, 200) or lcd.RGB(60, 60, 60))
        lcd.color(textColor)
        lcd.font(FONT_XXL)
        local tw, th = lcd.getTextSize(icon)
        lcd.drawText(x + (size - tw) / 2, y + (size - th) / 2, icon)
    else
        -- Button text
        local textColor = active and lcd.RGB(255, 255, 255) or (isDarkMode and lcd.RGB(200, 200, 200) or lcd.RGB(60, 60, 60))
        lcd.color(textColor)
        lcd.font(FONT_L)
        local tw, th = lcd.getTextSize(label)
        lcd.drawText(x + (size - tw) / 2, y + (size - th) / 2, label)
    end
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
    
    -- Battery icon frame (scaled down)
    local battX = x + 15
    local battY = y + h / 2 - 18
    local battW = 80
    local battH = 36
    
    lcd.color(isDarkMode and lcd.RGB(255, 255, 255) or lcd.RGB(0, 0, 0))
    lcd.drawRectangle(battX, battY, battW, battH, 2)
    
    -- Battery cap
    local capW = 6
    local capH = 20
    lcd.drawFilledRectangle(battX + battW, battY + (battH - capH) / 2, capW, capH)
    
    -- Battery fill
    local fillW = (battW - 8) * (percent / 100)
    
    if percent > 50 then
        lcd.color(lcd.RGB(0, 255, 0))
    elseif percent > 20 then
        lcd.color(lcd.RGB(255, 200, 0))
    else
        lcd.color(lcd.RGB(255, 0, 0))
    end
    lcd.drawFilledRectangle(battX + 4, battY + 4, fillW, battH - 8)
    
    -- Battery text
    lcd.color(isDarkMode and lcd.RGB(255, 255, 255) or lcd.RGB(0, 0, 0))
    lcd.font(FONT_L)
    local battText = string.format("%d%%", percent)
    local tw, th = lcd.getTextSize(battText)
    lcd.drawText(battX + battW + 15, battY + (battH - th) / 2, battText)
    
    -- Voltage display
    local voltText = string.format("%.1fV", voltage)
    lcd.font(FONT_STD)
    tw, th = lcd.getTextSize(voltText)
    lcd.drawText(battX + battW + 15, battY + battH / 2 + 8, voltText)
end

local function create(zone, options)
    loadAssets()
    return {
        zone = zone,
        options = options
    }
end

local function paint(widget)
    if not widget then
        return
    end
    
    local screenW, screenH = lcd.getWindowSize()
    local zone = {x = 0, y = 0, w = screenW, h = screenH}
    local isDarkMode = lcd.darkMode()
    
    -- Clear background
    lcd.color(isDarkMode and lcd.RGB(20, 20, 20) or lcd.RGB(240, 240, 240))
    lcd.drawFilledRectangle(zone.x, zone.y, zone.w, zone.h)
    
    -- Calculate button layout (square buttons) - smaller size
    local buttonSize = math.min(70, (zone.w - 80) / 4)
    local spacing = 15
    local totalWidth = buttonSize * 4 + spacing * 3
    local startX = zone.x + (zone.w - totalWidth) / 2
    
    -- First row of control buttons with icons
    local buttonY1 = zone.y + 15
    renderControlButton(startX, buttonY1, buttonSize, "LIGHTS", state.lightsOn, lcd.RGB(255, 200, 0), "💡", nil)
    -- Left indicator with blinking
    local leftActive = state.indicatorLeft and state.blinkState
    renderControlButton(startX + buttonSize + spacing, buttonY1, buttonSize, "LEFT", leftActive, lcd.RGB(255, 140, 0), nil, assets.arrowLeft)
    -- Right indicator with blinking
    local rightActive = state.indicatorRight and state.blinkState
    renderControlButton(startX + (buttonSize + spacing) * 2, buttonY1, buttonSize, "RIGHT", rightActive, lcd.RGB(255, 140, 0), "►", nil)
    renderControlButton(startX + (buttonSize + spacing) * 3, buttonY1, buttonSize, "HORN", state.hornActive, lcd.RGB(200, 0, 0), "🔊", nil)
    
    -- Second row of control buttons with icons
    local buttonY2 = buttonY1 + buttonSize + spacing
    renderControlButton(startX, buttonY2, buttonSize, "BTN 5", state.button5, lcd.RGB(0, 150, 255), "5", nil)
    renderControlButton(startX + buttonSize + spacing, buttonY2, buttonSize, "BTN 6", state.button6, lcd.RGB(0, 200, 100), "6", nil)
    renderControlButton(startX + (buttonSize + spacing) * 2, buttonY2, buttonSize, "BTN 7", state.button7, lcd.RGB(150, 0, 255), "7", nil)
    renderControlButton(startX + (buttonSize + spacing) * 3, buttonY2, buttonSize, "BTN 8", state.button8, lcd.RGB(255, 100, 150), "8", nil)
    
    -- Battery status - moved up with smaller height
    local battY = buttonY2 + buttonSize + 20
    local battW = zone.w - 80
    local battH = 60
    renderBatteryStatus(zone.x + 40, battY, battW, battH, state.batteryVoltage, state.batteryPercent)
end

local function event(widget, category, value, x, y)
    if not widget then
        return false
    end
    -- print("Event received: category=" .. tostring(category) .. " value=" .. tostring(value) .. " x=" .. tostring(x) .. " y=" .. tostring(y))
    
    -- Handle touch events
    if category == 1 and value == 16641 then
        local screenW, screenH = lcd.getWindowSize()
        local zone = {x = 0, y = 0, w = screenW, h = screenH}
        local buttonSize = math.min(70, (zone.w - 80) / 4)
        local spacing = 15
        local totalWidth = buttonSize * 4 + spacing * 3
        local startX = zone.x + (zone.w - totalWidth) / 2
        local buttonY1 = zone.y + 15
        local buttonY2 = buttonY1 + buttonSize + spacing
        
        -- Check first row button presses
        if y >= buttonY1 and y <= buttonY1 + buttonSize then
            -- Lights button
            if x >= startX and x <= startX + buttonSize then
                state.lightsOn = not state.lightsOn
                lcd.invalidate()
                print("Lights toggled: " .. tostring(state.lightsOn))
                return true
            -- Left indicator
            elseif x >= startX + buttonSize + spacing and x <= startX + (buttonSize + spacing) * 2 - spacing then
                state.indicatorLeft = not state.indicatorLeft
                if state.indicatorLeft then
                    state.indicatorRight = false
                end
                lcd.invalidate()
                return true
            -- Right indicator
            elseif x >= startX + (buttonSize + spacing) * 2 and x <= startX + (buttonSize + spacing) * 3 - spacing then
                state.indicatorRight = not state.indicatorRight
                if state.indicatorRight then
                    state.indicatorLeft = false
                end
                lcd.invalidate()
                return true
            -- Horn button
            elseif x >= startX + (buttonSize + spacing) * 3 and x <= startX + (buttonSize + spacing) * 4 then
                state.hornActive = not state.hornActive
                lcd.invalidate()
                return true
            end
        -- Check second row button presses
        elseif y >= buttonY2 and y <= buttonY2 + buttonSize then
            -- Button 5
            if x >= startX and x <= startX + buttonSize then
                state.button5 = not state.button5
                lcd.invalidate()
                return true
            -- Button 6
            elseif x >= startX + buttonSize + spacing and x <= startX + (buttonSize + spacing) * 2 - spacing then
                state.button6 = not state.button6
                lcd.invalidate()
                return true
            -- Button 7
            elseif x >= startX + (buttonSize + spacing) * 2 and x <= startX + (buttonSize + spacing) * 3 - spacing then
                state.button7 = not state.button7
                lcd.invalidate()
                return true
            -- Button 8
            elseif x >= startX + (buttonSize + spacing) * 3 and x <= startX + (buttonSize + spacing) * 4 then
                state.button8 = not state.button8
                lcd.invalidate()
                return true
            end
        end
    end
    return false
end

local function wakeup(widget)
    local screenW, screenH = lcd.getWindowSize()
    
    -- Blink indicators at 500ms interval
    local currentTime = os.clock()
    if currentTime - state.lastBlinkTime >= 0.5 then
        state.blinkState = not state.blinkState
        state.lastBlinkTime = currentTime
        
        -- Invalidate display if any indicator is active
        if state.indicatorLeft or state.indicatorRight then
            lcd.invalidate()
        end
    end
end

-- Register the widget with Ethos
local function init()
    -- Register custom source for indicator control
    system.registerSource({
        key = "mogind",
        name = "Mogster Indicator",
        getValue = getIndicatorValue,
        unit = UNIT_RAW
    })
    
    system.registerWidget({
        key = "mogster",
        name = name,
        create = create,
        paint = paint,
        event = event,
        wakeup = wakeup
    })
end

return {init = init}
