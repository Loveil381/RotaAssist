------------------------------------------------------------------------
-- RotaAssist - Cooldown Panel
-- Horizontal strip showing major cooldown icons with remaining time.
-- Ready icons glow, cooling-down icons display remaining seconds.
-- Independently draggable from the main display.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local CooldownPanel = {}
RA:RegisterModule("CooldownPanel", CooldownPanel)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

local container = nil
---@type table<number, table>  spellID → IconWidget instance
local cdWidgets = {}
local isVisible = true
local isLocked  = false

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local ICON_SIZE    = 32
local ICON_SPACING = 3
local MAX_ICONS    = 12

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

---Format a cooldown remaining time as a short string.
---@param remaining number  Seconds remaining
---@return string
local function formatCooldown(remaining)
    if not remaining or remaining <= 0 then
        return RA.L and RA.L["CD_READY"] or "Ready"
    end
    if remaining >= 60 then
        local m = math.floor(remaining / 60)
        local s = math.floor(remaining % 60)
        return string.format(RA.L and RA.L["CD_MINUTES"] or "%d:%02d", m, s)
    end
    return string.format(RA.L and RA.L["CD_SECONDS"] or "%ds", math.floor(remaining + 0.5))
end

------------------------------------------------------------------------
-- Frame Construction
------------------------------------------------------------------------

---Build a single cooldown icon using IconWidget.
---@param spellID number
---@param index   number  1-based horizontal position
---@return table widget   IconWidget instance
local function createCDWidget(spellID, index)
    -- Use the RA.UI.IconWidget class (same as MainDisplay / CooldownBar)
    local widget = RA.UI.IconWidget:Create(container, ICON_SIZE,
        "RotaAssistCD_" .. spellID)

    -- Position: first icon left-anchored, rest relative to previous
    if index == 1 then
        widget.frame:SetPoint("LEFT", container, "LEFT", 2, 0)
    else
        local offset = (index - 1) * (ICON_SIZE + ICON_SPACING) + 2
        widget.frame:SetPoint("LEFT", container, "LEFT", offset, 0)
    end

    -- Load static spell texture / name
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    if ok and info then
        widget.icon:SetTexture(info.iconID or 134400)
    end

    -- Remaining-time text shown in centre of icon
    widget.timeText = widget.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    widget.timeText:SetPoint("CENTER", widget.frame, "CENTER", 0, 0)
    widget.timeText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    widget.timeText:SetTextColor(1, 1, 1)

    -- Tooltip
    widget.frame:EnableMouse(true)
    widget.frame:SetScript("OnEnter", function(self)
        local cdTracker = RA:GetModule("CooldownTracker")
        if cdTracker then
            local state = cdTracker:GetCooldownState(spellID)
            if state then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(state.name or ("Spell#" .. spellID), 1, 1, 1)
                local L = RA.L
                local cdStr = formatCooldown(state.remaining)
                GameTooltip:AddLine(string.format(
                    L and L["TOOLTIP_COOLDOWN"] or "Cooldown: %s", cdStr),
                    0.8, 0.8, 0.8)
                GameTooltip:Show()
            end
        end
    end)
    widget.frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    widget._spellID = spellID
    return widget
end

---Build the cooldown panel container frame.
local function createPanel()
    if container then return end

    local db = RA.db and RA.db.profile.cooldowns or {}

    container = CreateFrame("Frame", "RotaAssist_CooldownPanel", UIParent, "BackdropTemplate")
    container:SetSize(200, ICON_SIZE + 4)
    container:SetScale(db.panelScale or 0.8)
    container:SetFrameStrata("MEDIUM")
    container:SetFrameLevel(8)
    container:SetClampedToScreen(true)
    container:SetMovable(true)
    container:EnableMouse(true)

    -- Position
    local anchor = db.panelAnchor or "CENTER"
    local aX     = db.panelAnchorX or 0
    local aY     = db.panelAnchorY or -260
    container:SetPoint(anchor, UIParent, anchor, aX, aY)

    -- Background
    container:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    container:SetBackdropColor(0, 0, 0, 0.5)
    container:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)

    -- Drag (locked flag applied in applyLock below)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self)
        if not isLocked then self:StartMoving() end
    end)
    container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        if RA.db and RA.db.profile.cooldowns then
            RA.db.profile.cooldowns.panelAnchor  = point
            RA.db.profile.cooldowns.panelAnchorX = x
            RA.db.profile.cooldowns.panelAnchorY = y
        end
    end)

    isLocked = db.panelLocked or false
end

---Populate cooldown icon widgets from CooldownTracker's tracked spells.
local function populateIcons()
    if not container then return end

    -- Hide & release old widgets
    for _, widget in pairs(cdWidgets) do
        widget.frame:Hide()
    end
    cdWidgets = {}

    local cdTracker = RA:GetModule("CooldownTracker")
    if not cdTracker then return end

    local allCD = cdTracker:GetAllCooldowns()
    -- Sort by spellID for consistent ordering
    local sortedIDs = {}
    for spellID in pairs(allCD) do
        sortedIDs[#sortedIDs + 1] = spellID
    end
    table.sort(sortedIDs)

    local index = 0
    for _, spellID in ipairs(sortedIDs) do
        if index >= MAX_ICONS then break end
        if cdTracker:IsSpellTracked(spellID) then
            index = index + 1
            cdWidgets[spellID] = createCDWidget(spellID, index)
        end
    end

    -- Resize container to fit icons
    if index > 0 then
        local totalWidth = (ICON_SIZE * index) + (ICON_SPACING * (index - 1)) + 4
        container:SetSize(totalWidth, ICON_SIZE + 4)
    end
end

------------------------------------------------------------------------
-- Update Loop
------------------------------------------------------------------------

---Update all cooldown icon states (text, desaturation, cooldown swirl).
local function refreshCooldowns()
    if not container or not isVisible then return end

    local cdTracker = RA:GetModule("CooldownTracker")
    if not cdTracker then return end

    for spellID, widget in pairs(cdWidgets) do
        local state = cdTracker:GetCooldownState(spellID)
        if state then
            if state.ready then
                widget.timeText:SetText("")
                widget:SetDesaturated(false)
                widget:SetAlert(false)
                widget.cooldown:Clear()
                widget.frame:SetBackdropBorderColor(0.0, 1.0, 0.0, 1)
            else
                widget.timeText:SetText(formatCooldown(state.remaining))
                widget:SetDesaturated(true)
                widget:SetAlert(false)
                -- Drive the cooldown swirl using start/duration from state
                if state.start and state.duration and state.duration > 1.5 then
                    widget.cooldown:SetCooldown(state.start, state.duration)
                else
                    widget.cooldown:Clear()
                end
                widget.frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
            end
        end
    end
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function CooldownPanel:OnInitialize()
    -- Nothing needed at init time; panel is built in OnEnable
end

function CooldownPanel:OnEnable()
    local db = RA.db and RA.db.profile.cooldowns or {}
    -- Respect user preference; default to showing panel
    if db.enabled == false or db.showPanel == false then return end

    createPanel()

    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ROTAASSIST_COOLDOWNS_UPDATED", "CooldownPanel", function()
            refreshCooldowns()
        end)
        eh:Subscribe("ROTAASSIST_SPEC_CHANGED", "CooldownPanel", function()
            -- Rebuild icons when spec changes (different spells tracked)
            C_Timer.After(0.5, populateIcons)
        end)
        eh:Subscribe("ROTAASSIST_SETTINGS_RESET", "CooldownPanel", function()
            if container then
                local dbNow = RA.db and RA.db.profile.cooldowns or {}
                container:SetScale(dbNow.panelScale or 0.8)
                isLocked = dbNow.panelLocked or false
            end
        end)
    end
end

function CooldownPanel:OnPlayerEnteringWorld()
    C_Timer.After(1.5, function()
        populateIcons()
        refreshCooldowns()
    end)
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Toggle the cooldown panel on/off.
function CooldownPanel:Toggle()
    if not container then return end
    isVisible = not isVisible
    if isVisible then
        container:Show()
    else
        container:Hide()
    end
end

---Force a refresh of all cooldown icons.
function CooldownPanel:Refresh()
    refreshCooldowns()
end
