------------------------------------------------------------------------
-- RotaAssist - Main Display (T-Shaped Layout)
-- Fully rewritten UI to support the new T-shaped layout:
--       [PHASE INDICATOR]
--   [CD1] [CD2] [MAIN] [CD3] [CD4]
--                [+1]
--                [+2]
--               [DEF]
--             [RESOURCE]
--             [ACCURACY]
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local MainDisplay = {}
RA:RegisterModule("MainDisplay", MainDisplay)

local FRAME_NAME = "RotaAssistMainFrame"
local MAX_PREDICTIONS = 2
local MAX_CDS = 4

------------------------------------------------------------------------
-- Internal State & UI Elements
------------------------------------------------------------------------

local mainFrame = nil
local elements = {
    phaseIndicator = nil,
    mainIcon = nil,
    predictions = {},
    cdBarLeft = nil,
    cdBarRight = nil,
    defensive = nil,
    resource = nil,
    accuracy = nil,
    prePull = nil,
    interruptAlert = nil
}

local inCombat = false
local outOfCombatTimer = nil
local lastDisplayed = {
    mainSpell = nil,
    predSpells = {}
}

------------------------------------------------------------------------
-- Layout Engine
------------------------------------------------------------------------

local function buildLayout()
    mainFrame = CreateFrame("Button", FRAME_NAME, UIParent, "BackdropTemplate")
    mainFrame:SetSize(250, 240)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetClampedToScreen(true)
    
    local dbDisplay = RA.db and RA.db.profile.display or {}
    local alpha = dbDisplay.bgAlpha or 0.5
    
    if not dbDisplay.hideBackground then
        mainFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        mainFrame:SetBackdropColor(0, 0, 0, alpha)
        mainFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, math.min(1.0, alpha + 0.3))
    end
    
    -- Main Icon (Center top-ish)
    elements.mainIcon = RA.UI.IconWidget:Create(mainFrame, 48, "RA_MainIcon")
    elements.mainIcon.frame:SetPoint("CENTER", mainFrame, "TOP", 0, -60)
    
    -- Phase Indicator (Above Main Icon)
    elements.phaseIndicator = RA.UI.PhaseIndicator:Create(mainFrame)
    elements.phaseIndicator.frame:SetPoint("BOTTOM", elements.mainIcon.frame, "TOP", 0, 8)
    
    -- CD Bars (Split left and right)
    elements.cdBarLeft = RA.UI.CooldownBar:Create(mainFrame, math.floor(MAX_CDS/2))
    elements.cdBarLeft.frame:SetPoint("RIGHT", elements.mainIcon.frame, "LEFT", -8, 0)
    
    elements.cdBarRight = RA.UI.CooldownBar:Create(mainFrame, math.ceil(MAX_CDS/2))
    elements.cdBarRight.frame:SetPoint("LEFT", elements.mainIcon.frame, "RIGHT", 8, 0)
    
    -- Interrupt Alert (Above Main Icon, below Phase)
    elements.interruptAlert = RA.UI.IconWidget:Create(mainFrame, 36, "RA_InterruptIcon")
    elements.interruptAlert.frame:SetPoint("BOTTOM", elements.mainIcon.frame, "TOP", 0, 4)
    
    elements.interruptAlert.kickText = elements.interruptAlert.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    elements.interruptAlert.kickText:SetPoint("CENTER", elements.interruptAlert.frame, "CENTER", 0, 0)
    elements.interruptAlert.kickText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    elements.interruptAlert.kickText:SetText(RA.L and RA.L["INTERRUPT_ALERT"] or "KICK!")
    elements.interruptAlert.kickText:SetTextColor(1, 0.2, 0.2)
    elements.interruptAlert.frame:Hide()
    
    -- Predictions (Vertical column below Main)
    for i = 1, MAX_PREDICTIONS do
        local pred = RA.UI.IconWidget:Create(mainFrame, 32)
        if i == 1 then
            pred.frame:SetPoint("TOP", elements.mainIcon.frame, "BOTTOM", 0, -8)
        else
            pred.frame:SetPoint("TOP", elements.predictions[i-1].frame, "BOTTOM", 0, -4)
        end
        pred.frame:SetAlpha(0.8)
        elements.predictions[i] = pred
    end
    
    -- Defensive Alert (Below predictions)
    elements.defensive = RA.UI.DefensiveAlert:Create(mainFrame)
    elements.defensive.iconWidget.frame:SetPoint("TOP", elements.predictions[MAX_PREDICTIONS].frame, "BOTTOM", 0, -8)
    
    -- Resource Bar (Bottom)
    elements.resource = RA.UI.ResourceBar:Create(mainFrame, 48, 6)
    elements.resource.bg:SetPoint("TOP", elements.defensive.iconWidget.frame, "BOTTOM", 0, -8)
    
    -- Accuracy Meter (Below Resource Bar)
    elements.accuracy = RA.UI.AccuracyMeter:Create(mainFrame, 120, 14)
    elements.accuracy.frame:SetPoint("TOP", elements.resource.bg, "BOTTOM", 0, -4)
    
    -- Pre-Pull Panel (Attached below the main frame)
    elements.prePull = RA.UI.PrePullPanel:Create(mainFrame)
    elements.prePull.frame:SetPoint("TOP", mainFrame, "BOTTOM", 0, -5)
    
    -- Load position & scale
    local scale = dbDisplay.scale or 1.0
    mainFrame:SetScale(scale)
    
    local p = dbDisplay.point
    if p and #p == 4 then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
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
    
    -- 1. Main Icon
    if data.main then
        if lastDisplayed.mainSpell ~= data.main.spellID then
            local ok, info = pcall(C_Spell.GetSpellInfo, data.main.spellID)
            local tex = ok and info and info.iconID or 134400
            elements.mainIcon:SetSpell(data.main.spellID, tex)
            lastDisplayed.mainSpell = data.main.spellID
        end
        
        -- Flash boundary if requested (handled in Interrupt but we can glow normally here)
        elements.mainIcon:SetGlow(true) 
        elements.mainIcon.frame:Show()
    else
        elements.mainIcon:Clear()
        elements.mainIcon.frame:Hide()
        lastDisplayed.mainSpell = nil
    end
    
    -- 2. Predictions
    for i = 1, MAX_PREDICTIONS do
        local predData = data.next[i]
        local widget = elements.predictions[i]
        
        if predData then
            if lastDisplayed.predSpells[i] ~= predData.spellID then
                local ok, info = pcall(C_Spell.GetSpellInfo, predData.spellID)
                local tex = ok and info and info.iconID or 134400
                widget:SetSpell(predData.spellID, tex)
                lastDisplayed.predSpells[i] = predData.spellID
            end
            widget:SetConfidence(predData.confidence or 1.0)
            widget.frame:Show()
        else
            widget:Clear()
            widget.frame:Hide()
            lastDisplayed.predSpells[i] = nil
        end
    end
    
    -- 3. Cooldowns
    local leftCDs = {}
    local rightCDs = {}
    if data.cooldowns then
        for i, cd in ipairs(data.cooldowns) do
            if i <= math.floor(MAX_CDS/2) then leftCDs[#leftCDs + 1] = cd
            elseif i <= MAX_CDS then rightCDs[#rightCDs + 1] = cd end
        end
    end
    elements.cdBarLeft:Update(leftCDs)
    elements.cdBarRight:Update(rightCDs)
    
    -- 4. Defensive Alert
    if data.defensive then
        local ok, info = pcall(C_Spell.GetSpellInfo, data.defensive.spellID)
        local tex = ok and info and info.iconID or 134400
        elements.defensive:Trigger(data.defensive.spellID, tex, data.defensive.name)
    else
        elements.defensive:Dismiss()
    end
    
    -- 5. Resource Bar
    -- WOW 12.0 SECRET VALUE SAFE: Use UpdateSecretSafe which passes
    -- secret UnitPower values directly to StatusBar:SetValue() (allowed)
    local specDetector = RA:GetModule("SpecDetector")
    if specDetector then
        local powerType = specDetector:GetPrimaryPowerType()
        if powerType then
            elements.resource:UpdateSecretSafe(powerType)
        end
    end
    
    -- 6. Phase Indicator
    local showCoach = RA.db and RA.db.profile.coach and RA.db.profile.coach.enabled
    if showCoach and data.aiContext and data.aiContext.phase then
        elements.phaseIndicator:Update(data.aiContext.phase, data.aiContext.phaseConfidence or 1.0)
    else
        elements.phaseIndicator:Hide()
    end

    -- 7. Accuracy Meter
    local showAcc = RA.db and RA.db.profile.accuracy and RA.db.profile.accuracy.enabled
    if showAcc and inCombat then
        local accTracker = RA:GetModule("AccuracyTracker")
        if accTracker then
            local stats = accTracker:GetSessionStats()
            if stats then
                elements.accuracy:Update(stats.smartAccuracy)
                elements.accuracy:Show()
            end
        end
    else
        elements.accuracy:Hide()
    end
    
    -- 8. Pre-Pull Panel
    if not inCombat then
        local ppc = RA:GetModule("PrePullChecker")
        if ppc then
            local ok, checks = pcall(ppc.RunChecks, ppc)
            if ok and checks then
                elements.prePull:Update(checks)
            end
        end
    else
        elements.prePull:Hide()
    end
end

------------------------------------------------------------------------
-- Interrupt Alert Handler
------------------------------------------------------------------------

local function UpdateInterrupt(active, data)
    if active and data then
        -- Optional sound alert for high urgency
        if data.urgency and data.urgency >= 0.8 then
            if RA.db and RA.db.profile.interrupt and RA.db.profile.interrupt.soundAlert then
                PlaySound(SOUNDKIT.RAID_WARNING)
            end
            -- Flash main icon border red
            elements.mainIcon:SetGlow(false)
            elements.mainIcon.frame:SetBackdropBorderColor(1, 0, 0, 1)
            C_Timer.After(0.3, function()
                if elements.mainIcon and elements.mainIcon.frame then
                    elements.mainIcon.frame:SetBackdropBorderColor(0, 0, 0, 1)
                    elements.mainIcon:SetGlow(true)
                end
            end)
        end
        
        local ok, info = pcall(C_Spell.GetSpellInfo, data.spellID)
        local tex = ok and info and info.iconID or 134400
        elements.interruptAlert:SetSpell(data.spellID, tex)
        
        if data.onCooldown then
            elements.interruptAlert.frame:SetAlpha(0.6)
            elements.interruptAlert:SetDesaturated(true)
            elements.interruptAlert:SetAlert(false)
            if data.startTime and data.duration then
                elements.interruptAlert.cooldown:SetCooldown(data.startTime, data.duration)
            end
        else
            elements.interruptAlert.frame:SetAlpha(1.0)
            elements.interruptAlert:SetDesaturated(false)
            elements.interruptAlert:SetAlert(true)
            elements.interruptAlert.cooldown:Clear()
        end
        
        elements.interruptAlert.frame:Show()
    else
        elements.interruptAlert.frame:Hide()
        elements.interruptAlert:Clear()
        elements.interruptAlert:SetAlert(false)
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
                    elements.prePull:Hide()
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
        if not inCombat then
            local ppc = RA:GetModule("PrePullChecker")
            if ppc then
                local ok, checks = pcall(ppc.RunChecks, ppc)
                if ok and checks then
                    elements.prePull:Update(checks)
                end
            end
        end
    end
    UpdateDisplay()
end

------------------------------------------------------------------------
-- Drag, Drop & Context Menu
------------------------------------------------------------------------

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
            if RA.db then
                RA.db.profile.display.point = { point, relPoint, x, y }
            end
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
    
    UpdateDisplay()
end

local function buildMenu(ownerFrame, rootDescription)
    -- Lock/Unlock
    local lockedText = (RA.L and RA.L["UNLOCK_POSITION"] or "Unlock Position")
    if RA.db and not RA.db.profile.display.locked then
        lockedText = (RA.L and RA.L["LOCK_POSITION"] or "Lock Position")
    end
    rootDescription:CreateButton(lockedText, function()
        RA.db.profile.display.locked = not RA.db.profile.display.locked
        applySettings()
    end)
    
    -- Combat Only
    local combatOnly = RA.db and RA.db.profile.display.combatOnly or false
    local combatText = (RA.L and RA.L["COMBAT_ONLY_TOOLTIP"] or "Combat Only")
    rootDescription:CreateCheckbox(combatText, function() return combatOnly end, function()
        RA.db.profile.display.combatOnly = not RA.db.profile.display.combatOnly
        checkVisibility()
    end)

    -- Phase Indicator
    local coachText = (RA.L and RA.L["SHOW_PHASE_INDICATOR"] or "Show Phase Indicator")
    rootDescription:CreateCheckbox(coachText, 
        function() return RA.db and RA.db.profile.coach and RA.db.profile.coach.enabled end, 
        function()
            if RA.db and RA.db.profile.coach then
                RA.db.profile.coach.enabled = not RA.db.profile.coach.enabled
                UpdateDisplay()
            end
        end
    )

    -- Accuracy Meter
    local accText = (RA.L and RA.L["SHOW_ACCURACY_METER"] or "Show Accuracy Meter")
    rootDescription:CreateCheckbox(accText, 
        function() return RA.db and RA.db.profile.accuracy and RA.db.profile.accuracy.enabled end, 
        function()
            if RA.db and RA.db.profile.accuracy then
                RA.db.profile.accuracy.enabled = not RA.db.profile.accuracy.enabled
                UpdateDisplay()
            end
        end
    )
    
    -- Scale sub-menu
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
    
    -- Open Options
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

    -- Use new SmartQueue events for primary drive
    eh:Subscribe("ROTAASSIST_QUEUE_UPDATED", "MainDisplay", UpdateDisplay)
    
    eh:Subscribe("ROTAASSIST_INTERRUPT_ALERT", "MainDisplay", UpdateInterrupt)
    eh:Subscribe("ROTAASSIST_SETTINGS_RESET", "MainDisplay", applySettings)
    eh:Subscribe("ACTIONBAR_SLOT_CHANGED", "MainDisplay", UpdateDisplay)
    
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
