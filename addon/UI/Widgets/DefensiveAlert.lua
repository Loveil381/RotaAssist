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

---Create a new Defensive Alert widget.
---@param parent table
---@return table widget
function DefensiveAlert:Create(parent)
    local obj = setmetatable({}, self)
    
    -- We can reuse the IconWidget class we already built
    obj.iconWidget = RA.UI.IconWidget:Create(parent, 28)
    obj.iconWidget.frame:Hide()
    
    -- Extra "USE!" text above the icon
    obj.useText = obj.iconWidget.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.useText:SetPoint("BOTTOM", obj.iconWidget.frame, "TOP", 0, 2)
    obj.useText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    obj.useText:SetTextColor(1, 0.2, 0.2)
    obj.useText:SetText("USE!")
    
    obj.activeSpell = nil
    obj.fadeTimer = nil
    
    return obj
end

---Trigger the defensive alert visually.
---@param spellID number
---@param texture number
---@param name string
function DefensiveAlert:Trigger(spellID, texture, name)
    if self.activeSpell == spellID and self.iconWidget.frame:IsShown() then
        return -- already pulsing this exact defensive
    end
    
    self.activeSpell = spellID
    self.iconWidget:SetSpell(spellID, texture)
    self.iconWidget:SetAlert(true) -- enable the red pulsating border
    
    -- Optional: Play a sound
    PlaySoundFile("Sound\\Interface\\RaidWarning.ogg", "Master")
    
    self.iconWidget.frame:SetAlpha(0)
    self.iconWidget.frame:Show()
    UIFrameFadeIn(self.iconWidget.frame, 0.2, 0, 1)
end

---Dismiss the defensive alert.
function DefensiveAlert:Dismiss()
    if not self.iconWidget.frame:IsShown() then return end
    
    self.activeSpell = nil
    self.iconWidget:SetAlert(false)
    
    UIFrameFadeOut(self.iconWidget.frame, 0.3, self.iconWidget.frame:GetAlpha(), 0)
    if self.fadeTimer then self.fadeTimer:Cancel() end
    self.fadeTimer = C_Timer.NewTimer(0.3, function()
        self.iconWidget.frame:Hide()
    end)
end
