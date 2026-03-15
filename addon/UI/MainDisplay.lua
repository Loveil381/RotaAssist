------------------------------------------------------------------------
-- RotaAssist - Main Display (HekiLight-style Horizontal Strip)
-- Rewritten for Round 15:
-- [MAIN] [PRED1] [PRED2] [PRED3]
-- Minimalistic, auto-hides CD spells, range/proc tracking.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local MainDisplay = {}
RA:RegisterModule("MainDisplay", MainDisplay)

local FRAME_NAME = "RotaAssistMainFrame"
local MAX_PREDICTIONS = 4

------------------------------------------------------------------------
-- Internal State & UI Elements
------------------------------------------------------------------------

local mainFrame = nil
local elements = {
    mainIcon = nil,
    predictions = {},
    defensive = nil,
    interruptAlert = nil
}

local inCombat = false
local outOfCombatTimer = nil
local lastDisplayed = {
    mainSpell = nil,
    predSpells = {}
}

------------------------------------------------------------------------
-- Keybind Cache
------------------------------------------------------------------------

local keybindCache = {}
local keybindCacheDirty = true

local function FindKeybindForSpell(spellID)
    if not spellID then return nil end
    if keybindCache[spellID] and not keybindCacheDirty then
        return keybindCache[spellID]
    end
    for slot = 1, 180 do
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" and id == spellID then
            local key = GetBindingKey("ACTIONBUTTON" .. slot)
            if not key and slot > 12 and slot <= 24 then key = GetBindingKey("MULTIACTIONBAR3BUTTON" .. (slot - 12))
            elseif not key and slot > 24 and slot <= 36 then key = GetBindingKey("MULTIACTIONBAR4BUTTON" .. (slot - 24))
            elseif not key and slot > 36 and slot <= 48 then key = GetBindingKey("MULTIACTIONBAR2BUTTON" .. (slot - 36))
            elseif not key and slot > 48 and slot <= 60 then key = GetBindingKey("MULTIACTIONBAR1BUTTON" .. (slot - 48))
            elseif not key and slot > 60 and slot <= 72 then key = GetBindingKey("MULTIACTIONBAR5BUTTON" .. (slot - 60))
            elseif not key and slot > 72 and slot <= 84 then key = GetBindingKey("MULTIACTIONBAR6BUTTON" .. (slot - 72))
            elseif not key and slot > 84 and slot <= 96 then key = GetBindingKey("MULTIACTIONBAR7BUTTON" .. (slot - 84))
            end
            if key then
                key = key:gsub("SHIFT%-", "S-"):gsub("CTRL%-", "C-"):gsub("ALT%-", "A-"):gsub("NUMPAD", "N")
                keybindCache[spellID] = key
                return key
            end
        end
    end
    keybindCache[spellID] = false
    return nil
end

------------------------------------------------------------------------
-- Layout Engine
------------------------------------------------------------------------

local function buildLayout()
    mainFrame = CreateFrame("Button", FRAME_NAME, UIParent, "BackdropTemplate")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetClampedToScreen(true)
    
    -- Main Icon
    elements.mainIcon = RA.UI.IconWidget:Create(mainFrame, 56, "RA_MainIcon")
    
    -- Predictions
    for i = 1, MAX_PREDICTIONS do
        local pred = RA.UI.IconWidget:Create(mainFrame, 40)
        pred.frame:SetAlpha(0.8)
        elements.predictions[i] = pred
    end
    
    -- Defensive & Interrupt are independent floating frames now
    elements.defensive = RA.UI.DefensiveAlert:Create()
    elements.interruptAlert = RA.UI.InterruptAlert:Create()
    
    local dbDisplay = RA.db and RA.db.profile.display or {}
    local p = dbDisplay.point
    if p and #p == 4 then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    end
end

local function applySettings()
    local display = RA.db and RA.db.profile.display or {}
    local isLocked = display.locked or false
    
    if isLocked then
        mainFrame:RegisterForDrag()
        mainFrame:SetScript("OnDragStart", nil)
        mainFrame:SetScript("OnDragStop", nil)
        mainFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0)
    else
        mainFrame:RegisterForDrag("LeftButton")
        mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
        mainFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, relTo, relPoint, x, y = self:GetPoint()
            if RA.db then RA.db.profile.display.point = { point, relPoint, x, y } end
        end)
        mainFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    end
    
    mainFrame:SetScale(display.scale or 1.0)
    
    if display.hideBackground then
        mainFrame:SetBackdrop(nil)
    else
        local alpha = display.bgAlpha or 0.5
        mainFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        mainFrame:SetBackdropColor(0, 0, 0, alpha)
        mainFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, math.min(1.0, alpha + 0.3))
    end
    
    -- Update Spacing and Count
    local iconCount = display.iconCount or 4
    if iconCount < 1 then iconCount = 1 end
    if iconCount > 5 then iconCount = 5 end
    
    local iconSpacing = display.iconSpacing or 4
    local mainSize = 56
    local predSize = 40
    
    local totalWidth = mainSize
    if iconCount > 1 then
        totalWidth = totalWidth + (iconCount - 1) * predSize + (iconCount - 1) * iconSpacing
    end
    mainFrame:SetSize(totalWidth + 16, mainSize + 16)
    
    elements.mainIcon.frame:ClearAllPoints()
    elements.mainIcon.frame:SetPoint("LEFT", mainFrame, "LEFT", 8, 0)
    
    for i = 1, MAX_PREDICTIONS do
        local pred = elements.predictions[i]
        pred.frame:ClearAllPoints()
        if i == 1 then
            pred.frame:SetPoint("LEFT", elements.mainIcon.frame, "RIGHT", iconSpacing, 0)
        else
            pred.frame:SetPoint("LEFT", elements.predictions[i-1].frame, "RIGHT", iconSpacing, 0)
        end
    end
end

------------------------------------------------------------------------
-- Update Logic
------------------------------------------------------------------------

local function UpdateDisplay()
    local smartQ = RA:GetModule("SmartQueueManager")
    if not smartQ then return end
    
    local data = smartQ:GetFinalQueue()
    if not data then return end
    
    -- Filter out passive and CD spells
    if data.main and RA:IsSpellPassive(data.main.spellID) then
        data.main = nil
    end
    if data.next then
        for i = #data.next, 1, -1 do
            local pData = data.next[i]
            if pData then
                if RA:IsSpellPassive(pData.spellID) then
                    table.remove(data.next, i)
                else
                    local cdInfo = C_Spell.GetSpellCooldown(pData.spellID)
                    if cdInfo and cdInfo.duration and cdInfo.duration > 1.5 then
                        table.remove(data.next, i)
                    end
                end
            end
        end
    end
    
    local displayConfig = RA.db and RA.db.profile.display or {}
    local iconCount = displayConfig.iconCount or 4
    local showProc = displayConfig.showProcGlow ~= false
    local showRange = displayConfig.showRangeIndicator ~= false
    
    -- 1. Main Icon
    if data.main then
        if lastDisplayed.mainSpell ~= data.main.spellID then
            local ok, info = pcall(C_Spell.GetSpellInfo, data.main.spellID)
            local tex = ok and info and info.iconID or 134400
            elements.mainIcon:SetSpell(data.main.spellID, tex)
            lastDisplayed.mainSpell = data.main.spellID
        end
        
        -- CD Swirl
        local cdSwirlInfo = C_Spell.GetSpellCooldown(data.main.spellID)
        if cdSwirlInfo and cdSwirlInfo.startTime and cdSwirlInfo.duration and cdSwirlInfo.duration > 1.5 then
            elements.mainIcon:SetCooldown(cdSwirlInfo.startTime, cdSwirlInfo.duration)
        else
            elements.mainIcon:SetCooldown(nil, nil)
        end
        
        -- Proc Glow
        local hasProc = false
        if showProc then
            local pOk, pRes = pcall(_G.C_SpellActivationOverlay.IsSpellOverlayed, data.main.spellID)
            if pOk and pRes then hasProc = true end
        end
        elements.mainIcon:SetGlow(hasProc or (data.main.source ~= "DEFENSIVE"))
        
        -- Range Indicator
        local inRange = true
        if showRange then
            local rOk, rRes = pcall(C_Spell.IsSpellInRange, data.main.spellID, "target")
            if rOk and rRes == false then inRange = false end
        end
        elements.mainIcon:SetOutOfRange(not inRange)
        
        local mainKey = FindKeybindForSpell(data.main.spellID)
        elements.mainIcon:SetKeybind((displayConfig.showKeybinds ~= false) and (mainKey or "") or "")
        
        if data.main.source == "APL_BLINDSPOT" then
            elements.mainIcon:SetConfidence(0.9)
        else
            elements.mainIcon:SetConfidence(0)
        end
        
        elements.mainIcon.frame:Show()
    else
        elements.mainIcon:Clear()
        elements.mainIcon.frame:Hide()
        lastDisplayed.mainSpell = nil
    end
    
    -- 2. Predictions
    local predSlots = iconCount - 1
    for i = 1, MAX_PREDICTIONS do
        local widget = elements.predictions[i]
        if i <= predSlots and data.next and data.next[i] then
            local predData = data.next[i]
            if lastDisplayed.predSpells[i] ~= predData.spellID then
                local ok, info = pcall(C_Spell.GetSpellInfo, predData.spellID)
                local tex = ok and info and info.iconID or 134400
                widget:SetSpell(predData.spellID, tex)
                lastDisplayed.predSpells[i] = predData.spellID
            end
            
            widget:SetConfidence(predData.confidence or 1.0)
            local predKey = FindKeybindForSpell(predData.spellID)
            widget:SetKeybind((displayConfig.showKeybinds ~= false) and (predKey or "") or "")
            
            widget.frame:Show()
        else
            widget:Clear()
            widget.frame:Hide()
            lastDisplayed.predSpells[i] = nil
        end
    end
    
    -- Defensive Alert
    if data.defensive then
        local ok, info = pcall(C_Spell.GetSpellInfo, data.defensive.spellID)
        local tex = ok and info and info.iconID or 134400
        elements.defensive:Trigger(data.defensive.spellID, tex, data.defensive.name)
    else
        elements.defensive:Dismiss()
    end
end

------------------------------------------------------------------------
-- Interrupt Alert Handler
------------------------------------------------------------------------

local function UpdateInterrupt(_, active, data)
    if not elements.interruptAlert then return end
    if active and data then
        local ok, info = pcall(C_Spell.GetSpellInfo, data.spellID)
        local tex = ok and info and info.iconID or 134400
        elements.interruptAlert:Trigger(data.spellID, tex, data)
    else
        elements.interruptAlert:Dismiss()
    end
end

------------------------------------------------------------------------
-- Combat State & Visibility
------------------------------------------------------------------------

local function checkVisibility()
    if not mainFrame then return end
    
    local combatOnly = RA.db and RA.db.profile.display.combatOnly or false
    
    if combatOnly and not inCombat then
        if not outOfCombatTimer then
            outOfCombatTimer = C_Timer.NewTimer(3.0, function()
                if not inCombat then
                    mainFrame:Hide()
                end
                outOfCombatTimer = nil
            end)
        end
    else
        if outOfCombatTimer then
            outOfCombatTimer:Cancel()
            outOfCombatTimer = nil
        end
        mainFrame:Show()
    end
    UpdateDisplay()
end

------------------------------------------------------------------------
-- Context Menu
------------------------------------------------------------------------

local function buildMenu(ownerFrame, rootDescription)
    local lockedText = (RA.L and RA.L["UNLOCK_POSITION"] or "Unlock Position")
    if RA.db and not RA.db.profile.display.locked then
        lockedText = (RA.L and RA.L["LOCK_POSITION"] or "Lock Position")
    end
    rootDescription:CreateButton(lockedText, function()
        RA.db.profile.display.locked = not RA.db.profile.display.locked
        applySettings()
    end)
    
    local combatOnly = RA.db and RA.db.profile.display.combatOnly or false
    local combatText = (RA.L and RA.L["COMBAT_ONLY_TOOLTIP"] or "Combat Only")
    rootDescription:CreateCheckbox(combatText, function() return combatOnly end, function()
        RA.db.profile.display.combatOnly = not RA.db.profile.display.combatOnly
        checkVisibility()
    end)
    
    local scaleStr = (RA.L and RA.L["ICON_SIZE_TOOLTIP"] or "Scale")
    local scaleMenu = rootDescription:CreateButton(scaleStr)
    for _, val in ipairs({0.75, 1.0, 1.25, 1.5}) do
        scaleMenu:CreateRadio(string.format("%d%%", val * 100),
        function() return RA.db and RA.db.profile.display.scale == val end,
        function()
            RA.db.profile.display.scale = val
            applySettings()
        end)
    end
    
    rootDescription:CreateDivider()
    
    local optsStr = (RA.L and RA.L["OPTIONS"] or "Options")
    rootDescription:CreateButton(optsStr, function()
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory(RA.name)
        elseif InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(RA.name)
        end
    end)
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function MainDisplay:OnInitialize()
    buildLayout()
end

function MainDisplay:OnEnable()
    applySettings()
    
    if MenuUtil and MenuUtil.CreateContextMenu then
        mainFrame:SetScript("OnMouseUp", function(_, button)
            if button == "RightButton" then
                MenuUtil.CreateContextMenu(mainFrame, buildMenu)
            end
        end)
    end

    local eh = RA:GetModule("EventHandler")
    if not eh then return end

    eh:Subscribe("ROTAASSIST_QUEUE_UPDATED", "MainDisplay", UpdateDisplay)
    eh:Subscribe("ROTAASSIST_INTERRUPT_ALERT", "MainDisplay", UpdateInterrupt)
    eh:Subscribe("ROTAASSIST_SETTINGS_RESET", "MainDisplay", applySettings)
    
    eh:Subscribe("ACTIONBAR_SLOT_CHANGED", "MainDisplay", function()
        keybindCacheDirty = true
        keybindCache = {}
        UpdateDisplay()
    end)
    
    eh:Subscribe("UPDATE_BINDINGS", "MainDisplay", function()
        keybindCacheDirty = true
        keybindCache = {}
        UpdateDisplay()
    end)
    
    eh:Subscribe("PLAYER_REGEN_DISABLED", "MainDisplay", function()
        inCombat = true
        checkVisibility()
    end)
    
    eh:Subscribe("PLAYER_REGEN_ENABLED", "MainDisplay", function()
        inCombat = false
        checkVisibility()
    end)
    
    checkVisibility()
end

---Public API
function MainDisplay:Toggle()
    if RA.db then
        RA.db.profile.display.combatOnly = not RA.db.profile.display.combatOnly
        checkVisibility()
    end
end

function MainDisplay:ToggleLock()
    if RA.db then
        RA.db.profile.display.locked = not RA.db.profile.display.locked
        applySettings()
    end
end
