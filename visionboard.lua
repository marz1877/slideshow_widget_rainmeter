local lastPaths = {}
local numSlots = 7
local isUpdating = false

-- Grid layout constants (used when numSlots > 7)
local BASE_W = 595   -- panel base width at Scale=1.0
local BASE_H = 620   -- panel base height at Scale=1.0
local SLOT_MARGIN = 10
local SLOT_GAP = 5

-- Per-count curated layouts (canvas: 595×620, margin=10, gap=5)
-- Inner usable area: 575 wide × 600 tall
-- Each LAYOUTS[n] = list of {x, y, w, h} at Scale=1.0
local LAYOUTS = {
    -- 1: Full panel hero
    {
        {10, 10, 575, 600},
    },
    -- 2: Left hero (60%) + right secondary (40%)
    {
        {10,  10, 350, 600},   -- left
        {365, 10, 220, 600},   -- right
    },
    -- 3: Large left + two stacked right
    {
        {10,  10,  350, 600},  -- left hero
        {365, 10,  220, 297},  -- top-right
        {365, 312, 220, 298},  -- bottom-right
    },
    -- 4: Large top-left + right pair + bottom wide
    {
        {10,  10,  350, 375},  -- top-left
        {365, 10,  220, 185},  -- top-right-a
        {365, 200, 220, 185},  -- top-right-b
        {10,  390, 575, 220},  -- bottom wide
    },
    -- 5: Large top-left + right pair + two bottom
    {
        {10,  10,  350, 375},  -- top-left
        {365, 10,  220, 185},  -- top-right-a
        {365, 200, 220, 185},  -- top-right-b
        {10,  390, 281, 220},  -- bottom-left
        {296, 390, 289, 220},  -- bottom-right
    },
    -- 6: Large top-left + right pair + three bottom
    {
        {10,  10,  350, 375},  -- top-left
        {365, 10,  220, 185},  -- top-right-a
        {365, 200, 220, 185},  -- top-right-b
        {10,  390, 185, 220},  -- bottom-a
        {200, 390, 185, 220},  -- bottom-b
        {390, 390, 195, 220},  -- bottom-c
    },
    -- 7: Original editorial layout
    {
        {10,  10,  335, 295},  -- large left
        {350, 10,  115, 115},  -- top-right small
        {470, 10,  115, 115},  -- top-right small
        {350, 130, 235, 175},  -- mid-right
        {10,  310, 165, 300},  -- bottom-left
        {180, 310, 165, 300},  -- bottom-mid
        {350, 310, 235, 300},  -- bottom-right
    },
    -- 8: Hero Left + 3 Stacked Right-Top + 4 Bottom Row
    {
        {10,  10,  350, 375},  -- Hero top-left
        {365, 10,  220, 120},  -- top-right 1
        {365, 135, 220, 120},  -- top-right 2
        {365, 260, 220, 125},  -- top-right 3
        {10,  390, 140, 220},  -- bottom 1
        {155, 390, 140, 220},  -- bottom 2
        {300, 390, 140, 220},  -- bottom 3
        {445, 390, 140, 220},  -- bottom 4
    },
    -- 9: 7-slot classic layout with bottom row subdivided into 5 columns
    {
        {10,  10,  335, 295},  -- large left hero
        {350, 10,  115, 115},  -- top-right small 1
        {470, 10,  115, 115},  -- top-right small 2
        {350, 130, 235, 175},  -- mid-right
        {10,  310, 111, 300},  -- bottom 1
        {126, 310, 111, 300},  -- bottom 2
        {242, 310, 111, 300},  -- bottom 3
        {358, 310, 111, 300},  -- bottom 4
        {474, 310, 111, 300},  -- bottom 5
    },
    -- 10: 7-slot layout with hero top-left, 3 mid-right, 6 bottom
    {
        {10,  10,  335, 295},  -- large left hero
        {350, 10,  115, 145},  -- top-right 1
        {470, 10,  115, 145},  -- top-right 2
        {350, 160, 235, 145},  -- mid-right
        {10,  310, 91,  300},  -- bottom 1
        {106, 310, 91,  300},  -- bottom 2
        {202, 310, 91,  300},  -- bottom 3
        {298, 310, 91,  300},  -- bottom 4
        {394, 310, 91,  300},  -- bottom 5
        {490, 310, 95,  300},  -- bottom 6
    },
    -- 11: Top hero banner + asymmetric 2-column mosaic below
    {
        {10,  10,  375, 235},  -- Top-left focal hero
        {390, 10,  195, 115},  -- Top-right 1
        {390, 130, 195, 115},  -- Top-right 2
        {10,  250, 137, 180},  -- Mid row 1
        {152, 250, 137, 180},  -- Mid row 2
        {294, 250, 137, 180},  -- Mid row 3
        {436, 250, 149, 180},  -- Mid row 4
        {10,  435, 137, 175},  -- Bottom row 1
        {152, 435, 137, 175},  -- Bottom row 2
        {294, 435, 137, 175},  -- Bottom row 3
        {436, 435, 149, 175},  -- Bottom row 4
    },
    -- 12: Dual Focal Points + Mosaic (Left portrait hero + right landscape hero + 10 supporting tiles)
    {
        {10,  10,  270, 290},  -- Left hero
        {285, 10,  290, 140},  -- Right top hero
        {285, 155, 142, 145},  -- Right mid 1
        {432, 155, 143, 145},  -- Right mid 2
        {10,  305, 137, 150},  -- Lower 1
        {152, 305, 137, 150},  -- Lower 2
        {294, 305, 138, 150},  -- Lower 3
        {437, 305, 138, 150},  -- Lower 4
        {10,  460, 137, 150},  -- Bottom 1
        {152, 460, 137, 150},  -- Bottom 2
        {294, 460, 138, 150},  -- Bottom 3
        {437, 460, 138, 150},  -- Bottom 4
    },
}

-- Reload paths from visionboard-paths.ini.
-- visionboard.ini uses @include to pull variables directly from that file,
-- so a skin refresh re-reads everything automatically.
-- This function is called from the right-click "Reload Paths" menu item.
function LoadPaths()
    -- Re-read ImageCount from the @include (already in memory after last refresh)
    numSlots = tonumber(SKIN:GetVariable('ImageCount', '7')) or 7
    if numSlots < 1  then numSlots = 1  end
    if numSlots > 25 then numSlots = 25 end
    for i = 1, 25 do lastPaths[i] = '' end
    ApplyLayout()
    print('VisionBoard: Paths reloaded from visionboard-paths.ini')
end

function Initialize()
    print("VisionBoard: Initializing...")
    LoadPaths()
    numSlots = tonumber(SKIN:GetVariable('ImageCount', '7')) or 7
    if numSlots < 1  then numSlots = 1  end
    if numSlots > 25 then numSlots = 25 end

    for i = 1, 25 do
        lastPaths[i] = ""
        SKIN:Bang('!SetVariable', 'Name' .. i, 'Loading...')
    end

    ApplyLayout()
end

-- Show/hide slots and set their geometry based on current numSlots
function ApplyLayout()
    -- Disable ALL measures and hide ALL slots first
    for i = 1, 25 do
        SKIN:Bang('!DisableMeasure', 'MeasureImage' .. i)
        SKIN:Bang('!HideMeterGroup', 'Slot' .. i)
    end

    if LAYOUTS[numSlots] then
        -- Curated layout for this exact count
        local layout = LAYOUTS[numSlots]
        for i = 1, numSlots do
            local s = layout[i]
            SetSlotGeometry(i, s[1], s[2], s[3], s[4])
            local p = SKIN:GetVariable('ImgPath' .. i, '')
            if p == '' then p = SKIN:GetVariable('ImgPath', '') end
            SKIN:Bang('!SetOption', 'MeasureImage' .. i, 'PathName', p)
            SKIN:Bang('!EnableMeasure', 'MeasureImage' .. i)
            SKIN:Bang('!ShowMeterGroup', 'Slot' .. i)
        end
        SKIN:Bang('!SetVariable', 'BoardW', tostring(BASE_W))
        SKIN:Bang('!SetVariable', 'BoardH', tostring(BASE_H))
    else
        -- Grid layout
        local cols = math.ceil(math.sqrt(numSlots))
        local rows = math.ceil(numSlots / cols)
        local slotW = math.floor((BASE_W - SLOT_MARGIN * 2 - SLOT_GAP * (cols - 1)) / cols)
        local slotH = math.floor((BASE_H - SLOT_MARGIN * 2 - SLOT_GAP * (rows - 1)) / rows)
        local panelH = SLOT_MARGIN * 2 + rows * slotH + SLOT_GAP * (rows - 1)

        SKIN:Bang('!SetVariable', 'BoardW', tostring(BASE_W))
        SKIN:Bang('!SetVariable', 'BoardH', tostring(panelH))

        local idx = 1
        for r = 0, rows - 1 do
            for c = 0, cols - 1 do
                if idx > numSlots then break end
                local x = SLOT_MARGIN + c * (slotW + SLOT_GAP)
                local y = SLOT_MARGIN + r * (slotH + SLOT_GAP)
                SetSlotGeometry(idx, x, y, slotW, slotH)
                local p = SKIN:GetVariable('ImgPath' .. idx, '')
                if p == '' then p = SKIN:GetVariable('ImgPath', '') end
                SKIN:Bang('!SetOption', 'MeasureImage' .. idx, 'PathName', p)
                SKIN:Bang('!EnableMeasure', 'MeasureImage' .. idx)
                SKIN:Bang('!ShowMeterGroup', 'Slot' .. idx)
                idx = idx + 1
            end
        end
    end

    SKIN:Bang('!Redraw')
end

-- Set the position and size of a slot via variables (meters use DynamicVariables)
function SetSlotGeometry(i, x, y, w, h)
    SKIN:Bang('!SetVariable', 'SlotX' .. i, tostring(x))
    SKIN:Bang('!SetVariable', 'SlotY' .. i, tostring(y))
    SKIN:Bang('!SetVariable', 'SlotW' .. i, tostring(w))
    SKIN:Bang('!SetVariable', 'SlotH' .. i, tostring(h))
end

-- Called by each measure's OnChangeAction or manually
function CheckUnique(slot)
    if isUpdating then return end
    slot = tonumber(slot)
    if slot > numSlots then return end

    local measure = SKIN:GetMeasure('MeasureImage' .. slot)
    if not measure then return end

    local currentPath = measure:GetStringValue()
    if currentPath == "" then return end

    -- Check for exact path duplicates in other active slots
    local isDuplicate = false
    for i = 1, numSlots do
        if i ~= slot and lastPaths[i] == currentPath then
            isDuplicate = true
            break
        end
    end

    if isDuplicate then
        isUpdating = true
        SKIN:Bang('!UpdateMeasure', 'MeasureImage' .. slot)
        isUpdating = false
    else
        lastPaths[slot] = currentPath

        -- Filename Cleaning: Strip path and extension
        local filename = currentPath:match("^.+\\(.-)%..-$") or currentPath:match("^.+/(.-)%..-$") or currentPath:match("(.+)%..-$") or currentPath

        SKIN:Bang('!SetVariable', 'Name' .. slot, filename)
        SKIN:Bang('!UpdateMeter', 'MeterImage' .. slot)

        print("VisionBoard: Slot " .. slot .. " verified: " .. filename)
    end
end

function Update()
    if lastPaths[1] == "" then
        for i = 1, numSlots do CheckUnique(i) end
    end
end

function ShuffleAll()
    print("VisionBoard: Shuffling all slots...")
    for i = 1, numSlots do
        SKIN:Bang('!UpdateMeasure', 'MeasureImage' .. i)
        CheckUnique(i)
    end
end

-- Rewrite a single key=value line in visionboard-paths.ini
-- Matches the first occurrence of "key=..."
local function WritePathsIni(key, value)
    local skinPath = SKIN:GetVariable('CURRENTPATH')
    local configPath = skinPath .. 'visionboard-paths.ini'
    local f = io.open(configPath, 'r')
    if not f then return end
    local lines = {}
    local replaced = false
    for line in f:lines() do
        local k = line:match('^%s*([%w]+)%s*=')
        if k == key and not replaced then
            table.insert(lines, key .. '=' .. value)
            replaced = true
        else
            table.insert(lines, line)
        end
    end
    f:close()
    local out = io.open(configPath, 'w')
    if not out then return end
    out:write(table.concat(lines, '\n') .. '\n')
    out:close()
    print('VisionBoard: WritePathsIni ' .. key .. '=' .. value)
end

-- Set the number of visible image slots (1-25) and persist it
function SetImageCount(n)
    n = tonumber(n) or 7
    if n < 1  then n = 1  end
    if n > 25 then n = 25 end
    numSlots = n
    print("VisionBoard: SetImageCount -> " .. n)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'ImageCount', tostring(n))
    SKIN:Bang('!SetVariable', 'ImageCount', tostring(n))
    for i = 1, 25 do lastPaths[i] = "" end
    ApplyLayout()
    for i = 1, numSlots do
        SKIN:Bang('!UpdateMeasure', 'MeasureImage' .. i)
    end
end

-- ==========================================
-- RESIZING / SCALING
-- ==========================================
-- State for drag-to-resize
local isDragging = false
local dragStartMouseX = 0
local dragStartMouseY = 0
local dragStartScale = 1.0

-- Called when user presses mouse button on the resize handle
-- $MouseX$/$MouseY$ here are skin-relative coords of the handle click (always near 0,0)
function StartResize()
    isDragging = true
    dragStartScale = tonumber(SKIN:GetVariable('Scale', '1.0')) or 1.0
    -- Record the skin's screen position and compute absolute mouse position
    -- SKIN:GetX()/GetY() return the skin's screen position
    local skinX = SKIN:GetX()
    local skinY = SKIN:GetY()
    -- We can't get absolute cursor pos without a plugin, so we track via
    -- the skin-relative mouse position from the Update tick using SKIN:GetMouse().
    -- Store 0,0 as start since handle is at top-left corner.
    dragStartMouseX = 0
    dragStartMouseY = 0
    print(string.format("VisionBoard: StartResize at scale=%.2f", dragStartScale))
end

-- Called when user releases mouse anywhere on the skin (via MeterBackdrop LeftMouseUpAction)
-- releaseX, releaseY are skin-relative coords of where the mouse was released
function EndResize(releaseX, releaseY)
    if not isDragging then return end
    isDragging = false

    local rx = tonumber(releaseX) or 0
    local ry = tonumber(releaseY) or 0

    -- rx/ry are skin-relative pixels; divide by base panel dimensions to get new scale
    local boardH = tonumber(SKIN:GetVariable('BoardH', tostring(BASE_H))) or BASE_H
    local scaleByX = rx / BASE_W
    local scaleByY = ry / boardH
    -- Weighted average, biased toward whichever axis moved more
    local newScale
    if math.abs(rx) < 20 and math.abs(ry) < 20 then
        -- tiny drag = accidental, ignore
        return
    elseif math.abs(rx) > math.abs(ry) then
        newScale = scaleByX
    else
        newScale = scaleByY
    end

    -- Clamp
    if newScale < 0.30 then newScale = 0.30 end
    if newScale > 3.00 then newScale = 3.00 end
    newScale = math.floor(newScale * 100 + 0.5) / 100

    print(string.format("VisionBoard: EndResize release=(%d,%d) newScale=%.2f", rx, ry, newScale))

    SKIN:Bang('!WriteKeyValue', 'Variables', 'Scale', string.format('%.2f', newScale))
    SKIN:Bang('!SetVariable', 'Scale', string.format('%.2f', newScale))
    SKIN:Bang('!Refresh')
end

function ResetScale()
    isDragging = false
    SKIN:Bang('!WriteKeyValue', 'Variables', 'Scale', '1.0')
    SKIN:Bang('!SetVariable', 'Scale', '1.0')
    SKIN:Bang('!Refresh')
end

-- Increment or decrement scale by delta (e.g. 0.05 or -0.05)
-- Used by scroll wheel on the resize handle
function ScaleStep(delta)
    local scale = tonumber(SKIN:GetVariable('Scale', '0.30')) or 0.30
    scale = scale + (tonumber(delta) or 0)
    if scale < 0.10 then scale = 0.10 end
    if scale > 3.00 then scale = 3.00 end
    scale = math.floor(scale * 100 + 0.5) / 100
    print(string.format("VisionBoard: ScaleStep -> %.2f", scale))
    SKIN:Bang('!WriteKeyValue', 'Variables', 'Scale', string.format('%.2f', scale))
    SKIN:Bang('!SetVariable', 'Scale', string.format('%.2f', scale))
    SKIN:Bang('!Refresh')
end

-- Jump to a specific scale value (used by right-click context menu)
function SetScale(value)
    local scale = tonumber(value) or 1.0
    if scale < 0.10 then scale = 0.10 end
    if scale > 3.00 then scale = 3.00 end
    scale = math.floor(scale * 100 + 0.5) / 100
    print(string.format("VisionBoard: SetScale -> %.2f", scale))
    SKIN:Bang('!WriteKeyValue', 'Variables', 'Scale', string.format('%.2f', scale))
    SKIN:Bang('!SetVariable', 'Scale', string.format('%.2f', scale))
    SKIN:Bang('!Refresh')
end

