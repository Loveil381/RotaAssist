------------------------------------------------------------------------
-- RotaAssist - PhaseIndicator Widget
-- 战斗阶段指示器 / Combat Phase Indicator UI
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

if not RA.UI then RA.UI = {} end

local RA_PhaseIndicator = {}
RA_PhaseIndicator.__index = RA_PhaseIndicator

local PHASE_COLORS = {
    BURST_PREPARE    = {1.0, 0.5, 0.0}, -- Orange
    BURST_ACTIVE     = {1.0, 0.4, 0.0}, -- Darker Orange
    BURST_COOLDOWN   = {0.4, 0.4, 0.4}, -- Gray
    AOE              = {0.6, 0.2, 0.8}, -- Purple
    EMERGENCY        = {0.8, 0.1, 0.1}, -- Red
    NORMAL           = {0.5, 0.5, 0.5}, -- Gray
    OPENER           = {0.2, 0.6, 1.0}, -- Blue
    PREPULL          = {0.1, 0.8, 0.8}, -- Cyan
    EXECUTE          = {0.8, 0.0, 0.2}, -- Dark Red
    RESOURCE_CAP     = {1.0, 0.8, 0.2}, -- Yellow
    RESOURCE_STARVED = {0.8, 0.6, 0.0}, -- Dark Yellow
    UNKNOWN          = {0.3, 0.3, 0.3}
}

local PHASE_ICONS = {
    BURST_PREPARE    = "Interface\\Icons\\Ability_Warrior_InnerRage",
    BURST_ACTIVE     = "Interface\\Icons\\Spell_Nature_BloodLust",
    BURST_COOLDOWN   = "Interface\\Icons\\Spell_Holy_AshesToAshes",
    AOE              = "Interface\\Icons\\Spell_Fire_MeteorStorm",
    EMERGENCY        = "Interface\\Icons\\Spell_Holy_GuardianSpirit",
    NORMAL           = "Interface\\Icons\\Ability_MeleeDamage",
    OPENER           = "Interface\\Icons\\Ability_Rogue_Ambush",
    PREPULL          = "Interface\\Icons\\Spell_Nature_TimeStop",
    EXECUTE          = "Interface\\Icons\\Ability_Rogue_Eviscerate",
    RESOURCE_CAP     = "Interface\\Icons\\Ability_Monk_ChiBurst",
    RESOURCE_STARVED = "Interface\\Icons\\Ability_DeathKnight_HungeringCold"
}

---Create a new PhaseIndicator widget.
---@param parent frame
---@return table
function RA_PhaseIndicator:Create(parent)
    local widget = setmetatable({}, self)

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(100, 20)
    
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1.0)
    widget.frame = frame

    -- Icon
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", frame, "LEFT", 4, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    widget.icon = icon

    -- Text
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    text:SetTextColor(1, 1, 1)
    text:SetText(RA.L and RA.L["UNKNOWN"] or "Unknown")
    widget.text = text

    -- Fade animations
    widget.agShow = frame:CreateAnimationGroup()
    local alphaIn = widget.agShow:CreateAnimation("Alpha")
    alphaIn:SetFromAlpha(0)
    alphaIn:SetToAlpha(1)
    alphaIn:SetDuration(0.15)
    widget.agShow:SetScript("OnPlay", function() frame:SetAlpha(0); frame:Show() end)
    widget.agShow:SetScript("OnFinished", function() frame:SetAlpha(1) end)

    widget.agHide = frame:CreateAnimationGroup()
    local alphaOut = widget.agHide:CreateAnimation("Alpha")
    alphaOut:SetFromAlpha(1)
    alphaOut:SetToAlpha(0)
    alphaOut:SetDuration(0.15)
    widget.agHide:SetScript("OnFinished", function() frame:Hide(); frame:SetAlpha(1) end)

    frame:Hide()
    widget.isVisible = false
    widget.currentPhase = nil

    return widget
end

---Update the phase safely.
---@param phase string Enum value
---@param confidence number 0.0 to 1.0
function RA_PhaseIndicator:Update(phase, confidence)
    if not phase or confidence < 0.4 then
        self:Hide()
        return
    end

    if self.currentPhase ~= phase then
        self.currentPhase = phase
        
        -- Localization / 本地化支持
        local displayStr = (RA.L and RA.L[phase]) or phase
        self.text:SetText(displayStr)
        
        -- Resize to fit / 自动调整宽度
        local textWidth = self.text:GetStringWidth()
        self.frame:SetWidth(textWidth + 26) -- 4 + 14 + 4 + text + 4

        -- Colors
        local color = PHASE_COLORS[phase] or PHASE_COLORS.UNKNOWN
        self.frame:SetBackdropColor(color[1], color[2], color[3], 0.8)
        self.frame:SetBackdropBorderColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, 1.0)

        -- Icon
        local tex = PHASE_ICONS[phase] or "Interface\\Icons\\INV_Misc_QuestionMark"
        self.icon:SetTexture(tex)
    end

    self:Show()
end

function RA_PhaseIndicator:Show()
    if self.isVisible then return end
    self.isVisible = true
    self.agHide:Stop()
    self.agShow:Play()
end

function RA_PhaseIndicator:Hide()
    if not self.isVisible then return end
    self.isVisible = false
    self.agShow:Stop()
    self.agHide:Play()
end

RA.UI.PhaseIndicator = RA_PhaseIndicator
