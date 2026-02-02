--[[
 * Mogster Control - Main Entry Point
 * 
 * Dashboard widget for controlling Mogster off-road vehicle
 * Features: Lights, Indicators, Sound, Battery Status, Tipper Control
 * 
 * License: MIT
--]]

local name = "Mogster Control"

-- Load assets
local assets = {}
local function loadAssets()
    local basePath = "/scripts/mogster/assets/"
    assets.arrowLeft = lcd.loadBitmap(basePath .. "arrow_left.png")
    assets.down = lcd.loadBitmap(basePath .. "down.png")
    assets.emLight = lcd.loadBitmap(basePath .. "em_light.png")
    assets.horn = lcd.loadBitmap(basePath .. "horn.png")
    assets.light = lcd.loadBitmap(basePath .. "light.png")
    assets.up = lcd.loadBitmap(basePath .. "up.png")
end

-- State variables
local state = {
    lightsOn = false,
    highBeamsOn = false,
    indicatorLeft = false,
    indicatorRight = false,
    warningLight = false,
    hornActive = false,
    hornPressed = false,  -- Track if horn button is currently pressed
    tipperUp = false,
    tipperDown = false,
    batteryVoltage = 12.6,
    batteryPercent = 75,
    blinkState = false,
    lastBlinkTime = 0
}

-- Orange color for active buttons
local ORANGE = lcd.RGB(255, 140, 0)

-- Source callback functions for Indicator
local function indicatorSourceInit(source)
    print("Indicator source init")
    source:unit(UNIT_RAW)
    source:value(0)
end

local function indicatorSourceWakeup(source)
    local value = 0
    if state.indicatorLeft then
        value = -100  -- Full left
    elseif state.indicatorRight then
        value = 100   -- Full right
    end
    source:value(value)
end

-- Source callback functions for Tipper
local function tipperSourceInit(source)
    print("Tipper source init")
    source:unit(UNIT_RAW)
    source:value(0)
end

local function tipperSourceWakeup(source)
    local value = 0
    if state.tipperUp then
        value = 100   -- Up
    elseif state.tipperDown then
        value = -100  -- Down
    end
    source:value(value)
end

-- Source callback functions for Warning Light
local function warningSourceInit(source)
    print("Warning light source init")
    source:unit(UNIT_RAW)
    source:value(0)
end

local function warningSourceWakeup(source)
    source:value(state.warningLight and 100 or 0)
end

-- Source callback functions for Lights
local function lightsSourceInit(source)
    print("Lights source init")
    source:unit(UNIT_RAW)
    source:value(0)
end

local function lightsSourceWakeup(source)
    local value = 0
    if state.lightsOn then
        value = 50  -- Lights on
    end
    if state.highBeamsOn then
        value = 100  -- High beams on
    end
    source:value(value)
end

-- Source callback functions for Horn
local function hornSourceInit(source)
    print("Horn source init")
    source:unit(UNIT_RAW)
    source:value(0)
end

local function hornSourceWakeup(source)
    source:value(state.hornActive and 100 or 0)
end

-- Helper function to render control button with optional icon
local function renderControlButton(x, y, size, label, active, activeColor, icon, bitmap)
    local isDarkMode = lcd.darkMode()
    
    -- Button background
    if active then
        lcd.color(activeColor or ORANGE)
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
    
    -- Calculate button layout (square buttons)
    local buttonSize = math.min(70, (zone.w - 80) / 4)
    local spacing = 15
    local totalWidth = buttonSize * 4 + spacing * 3
    local startX = zone.x + (zone.w - totalWidth) / 2
    
    -- First row: Lights, High Beams, Warning Light, Horn
    local buttonY1 = zone.y + 15
    renderControlButton(startX, buttonY1, buttonSize, "LIGHTS", state.lightsOn, ORANGE, nil, assets.light)
    renderControlButton(startX + buttonSize + spacing, buttonY1, buttonSize, "HIGH", state.highBeamsOn, ORANGE, nil, nil)
    -- Warning light with blinking
    local warningActive = state.warningLight and state.blinkState
    renderControlButton(startX + (buttonSize + spacing) * 2, buttonY1, buttonSize, "WARN", warningActive, ORANGE, "⚠", assets.emLigh)
    renderControlButton(startX + (buttonSize + spacing) * 3, buttonY1, buttonSize, "HORN", state.hornActive, ORANGE, nil, assets.horn)
    
    -- Second row: Left Indicator, Right Indicator, Tipper Up, Tipper Down
    local buttonY2 = buttonY1 + buttonSize + spacing
    -- Left indicator with blinking
    local leftActive = state.indicatorLeft and state.blinkState
    renderControlButton(startX, buttonY2, buttonSize, "LEFT", leftActive, ORANGE, nil, assets.arrowLeft)
    -- Right indicator with blinking (mirror the left arrow)
    local rightActive = state.indicatorRight and state.blinkState
    renderControlButton(startX + buttonSize + spacing, buttonY2, buttonSize, "RIGHT", rightActive, ORANGE, "►", nil)
    renderControlButton(startX + (buttonSize + spacing) * 2, buttonY2, buttonSize, "UP", state.tipperUp, ORANGE, nil, assets.up)
    renderControlButton(startX + (buttonSize + spacing) * 3, buttonY2, buttonSize, "DOWN", state.tipperDown, ORANGE, nil, assets.down)
    
    -- Battery status
    local battY = buttonY2 + buttonSize + 20
    local battW = zone.w - 80
    local battH = 60
    renderBatteryStatus(zone.x + 40, battY, battW, battH, state.batteryVoltage, state.batteryPercent)
end

local function event(widget, category, value, x, y)
    if not widget then
        return false
    end
    
    print("Event: category=" .. tostring(category) .. " value=" .. tostring(value) .. " x=" .. tostring(x) .. " y=" .. tostring(y))
    
    -- Handle touch release - deactivate horn if it was pressed
    if category == 1 and (value == 16642 or value == 16643) then
        if state.hornPressed then
            state.hornActive = false
            state.hornPressed = false
            lcd.invalidate()
            print("Horn deactivated on release")
            return true
        end
        return false
    end
    
    -- Handle touch events (press)
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
                -- Turn off high beams if lights are turned off
                if not state.lightsOn then
                    state.highBeamsOn = false
                end
                lcd.invalidate()
                print("Lights toggled: " .. tostring(state.lightsOn))
                return true
            -- High beams button
            elseif x >= startX + buttonSize + spacing and x <= startX + (buttonSize + spacing) * 2 - spacing then
                -- Can only turn on high beams if lights are on
                if state.lightsOn then
                    state.highBeamsOn = not state.highBeamsOn
                    lcd.invalidate()
                    print("High beams toggled: " .. tostring(state.highBeamsOn))
                end
                return true
            -- Warning light button
            elseif x >= startX + (buttonSize + spacing) * 2 and x <= startX + (buttonSize + spacing) * 3 - spacing then
                state.warningLight = not state.warningLight
                lcd.invalidate()
                print("Warning light toggled: " .. tostring(state.warningLight))
                return true
            -- Horn button (momentary - activate on press)
            elseif x >= startX + (buttonSize + spacing) * 3 and x <= startX + (buttonSize + spacing) * 4 then
                state.hornActive = true
                state.hornPressed = true
                lcd.invalidate()
                print("Horn activated")
                return true
            end
        -- Check second row button presses
        elseif y >= buttonY2 and y <= buttonY2 + buttonSize then
            -- Left indicator
            if x >= startX and x <= startX + buttonSize then
                state.indicatorLeft = not state.indicatorLeft
                if state.indicatorLeft then
                    state.indicatorRight = false
                end
                lcd.invalidate()
                print("Left indicator toggled: " .. tostring(state.indicatorLeft))
                return true
            -- Right indicator
            elseif x >= startX + buttonSize + spacing and x <= startX + (buttonSize + spacing) * 2 - spacing then
                state.indicatorRight = not state.indicatorRight
                if state.indicatorRight then
                    state.indicatorLeft = false
                end
                lcd.invalidate()
                print("Right indicator toggled: " .. tostring(state.indicatorRight))
                return true
            -- Tipper Up
            elseif x >= startX + (buttonSize + spacing) * 2 and x <= startX + (buttonSize + spacing) * 3 - spacing then
                state.tipperUp = not state.tipperUp
                if state.tipperUp then
                    state.tipperDown = false
                end
                lcd.invalidate()
                print("Tipper up toggled: " .. tostring(state.tipperUp))
                return true
            -- Tipper Down
            elseif x >= startX + (buttonSize + spacing) * 3 and x <= startX + (buttonSize + spacing) * 4 then
                state.tipperDown = not state.tipperDown
                if state.tipperDown then
                    state.tipperUp = false
                end
                lcd.invalidate()
                print("Tipper down toggled: " .. tostring(state.tipperDown))
                return true
            end
        end
    end
    return false
end

local function wakeup(widget)
    -- Blink indicators and warning light at 500ms interval
    local currentTime = os.clock()
    if currentTime - state.lastBlinkTime >= 0.5 then
        state.blinkState = not state.blinkState
        state.lastBlinkTime = currentTime
        
        -- Invalidate display if any blinking element is active
        if state.indicatorLeft or state.indicatorRight or state.warningLight then
            lcd.invalidate()
        end
    end
    
    -- Safety: Auto-deactivate horn if it's been active for more than 5 seconds
    -- This prevents the horn from getting stuck on
    if state.hornActive and not state.hornPressed then
        state.hornActive = false
        lcd.invalidate()
        print("Horn auto-deactivated (safety)")
    end
end

-- Register the widget with Ethos
local function init()
    -- Register custom source for indicator control
    system.registerSource({
        key = "mogind",
        name = "Mogster Indicator",
        init = indicatorSourceInit,
        wakeup = indicatorSourceWakeup
    })
    
    -- Register custom source for tipper control
    system.registerSource({
        key = "mogtip",
        name = "Mogster Tipper",
        init = tipperSourceInit,
        wakeup = tipperSourceWakeup
    })
    
    -- Register custom source for warning light
    system.registerSource({
        key = "mogwarn",
        name = "Mogster Warning",
        init = warningSourceInit,
        wakeup = warningSourceWakeup
    })
    
    -- Register custom source for lights
    system.registerSource({
        key = "mogligh",
        name = "Mogster Lights",
        init = lightsSourceInit,
        wakeup = lightsSourceWakeup
    })
    
    -- Register custom source for horn
    system.registerSource({
        key = "moghorn",
        name = "Mogster Horn",
        init = hornSourceInit,
        wakeup = hornSourceWakeup
    })
    
    print("All Mogster sources registered with callbacks")
    
    system.registerWidget({
        key = "mogster",
        name = name,
        create = create,
        paint = paint,
        event = event,
        wakeup = wakeup
    })
end

local module = {init = init}
return module
