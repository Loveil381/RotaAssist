------------------------------------------------------------------------
-- RotaAssist - DefensiveAlert Widget
-- Pulsing icon popping up for low HP defensive recommendation.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.UI = RA.UI or {}
RA.UI.DefensiveAlert = {}
local DefensiveAlert = RA.UI.DefensiveAlert
DefensiveAlert.__index = DefensiveAlert

---Create a new Defensive Alert widget as an independent floating frame.
---@return table widget
function DefensiveAlert:Create()
    local obj = setmetatable({}, self)
    
    -- Container frame attached to UIParent
    local f = CreateFrame("Frame", "RA_DefensiveAlertContainer", UIParent)
    f:SetSize(64, 64)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 150) -- Default position: upper center
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if RA.db and RA.db.profile.display and RA.db.profile.display.locked then return end
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    
    obj.container = f
    
    -- IconWidget
    obj.iconWidget = RA.UI.IconWidget:Create(f, 64, "RA_DefensiveAlertIcon")
    obj.iconWidget.frame:SetPoint("CENTER", f, "CENTER", 0, 0)
    
    -- Extra text above the icon / 图标上方额外文本
    obj.useText = obj.iconWidget.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.useText:SetPoint("BOTTOM", obj.iconWidget.frame, "TOP", 0, 4)
    obj.useText:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
    obj.useText:SetTextColor(1, 0.2, 0.2)
    obj.useText:SetText(RA.L and RA.L["USE_DEFENSIVE"] or "USE DEFENSIVE!")
    
    obj.activeSpell = nil
    obj.fadeTimer = nil
    
    -- Hide container initially
    obj.container:Hide()
    
    return obj
end

---Trigger the defensive alert visually.
---@param spellID number
---@param texture number
---@param name string
function DefensiveAlert:Trigger(spellID, texture, name)
    if self.activeSpell == spellID and self.container:IsShown() then
        -- Reset timer if triggered again while already showing
        if self.fadeTimer then self.fadeTimer:Cancel() end
        self.fadeTimer = C_Timer.NewTimer(2.0, function() self:Dismiss() end)
        return
    end
    
    self.activeSpell = spellID
    self.iconWidget:SetSpell(spellID, texture)
    self.iconWidget:SetAlert(true) -- enable the red pulsating border / 启用红色脉冲边框
    
    local defaultUseText = RA.L and RA.L["USE_DEFENSIVE"] or "USE DEFENSIVE!"
    self.useText:SetText(name or defaultUseText)
    
    -- Optional: Play a sound / 播放警告音效
    PlaySoundFile("Sound\\Interface\\RaidWarning.ogg", "Master")
    
    self.container:SetAlpha(0)
    self.container:Show()
    UIFrameFadeIn(self.container, 0.2, 0, 1)
    
    -- Auto-fade after 2s
    if self.fadeTimer then self.fadeTimer:Cancel() end
    self.fadeTimer = C_Timer.NewTimer(2.0, function() self:Dismiss() end)
end

---Dismiss the defensive alert.
function DefensiveAlert:Dismiss()
    if not self.container:IsShown() then return end
    
    self.activeSpell = nil
    self.iconWidget:SetAlert(false)
    
    UIFrameFadeOut(self.container, 0.3, self.container:GetAlpha(), 0)
    if self.fadeTimer then self.fadeTimer:Cancel() end
    self.fadeTimer = C_Timer.NewTimer(0.3, function()
        self.container:Hide()
    end)
end
