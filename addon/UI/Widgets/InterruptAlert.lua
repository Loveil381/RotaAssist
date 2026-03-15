------------------------------------------------------------------------
-- RotaAssist - InterruptAlert Widget
-- Standalone floating frame for interrupt recommendations.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.UI = RA.UI or {}
RA.UI.InterruptAlert = {}
local InterruptAlert = RA.UI.InterruptAlert
InterruptAlert.__index = InterruptAlert

---Create a new Interrupt Alert widget as an independent floating frame.
---@return table widget
function InterruptAlert:Create()
    local obj = setmetatable({}, self)
    
    -- Container frame attached to UIParent
    local f = CreateFrame("Frame", "RA_InterruptAlertContainer", UIParent)
    f:SetSize(48, 48)
    f:SetPoint("BOTTOM", UIParent, "CENTER", 0, -100) -- Default position: right above MainDisplay if it's near center
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
    obj.iconWidget = RA.UI.IconWidget:Create(f, 48, "RA_InterruptAlertIcon")
    obj.iconWidget.frame:SetPoint("CENTER", f, "CENTER", 0, 0)
    
    -- Extra text
    obj.useText = obj.iconWidget.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.useText:SetPoint("CENTER", obj.iconWidget.frame, "CENTER", 0, 0)
    obj.useText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    obj.useText:SetTextColor(1, 0.2, 0.2)
    obj.useText:SetText(RA.L and RA.L["INTERRUPT_ALERT"] or "KICK!")
    
    obj.activeSpell = nil
    obj.fadeTimer = nil
    obj.container:Hide()
    
    return obj
end

---Trigger the interrupt alert visually.
---@param spellID number
---@param texture number
---@param data table Interrupt data from SmartQueueManager
function InterruptAlert:Trigger(spellID, texture, data)
    self.activeSpell = spellID
    self.iconWidget:SetSpell(spellID, texture)
    
    if data and data.onCooldown then
        self.container:SetAlpha(0.6)
        self.iconWidget:SetDesaturated(true)
        self.iconWidget:SetAlert(false)
        if data.startTime and data.duration then
            self.iconWidget:SetCooldown(data.startTime, data.duration)
        end
    else
        self.container:SetAlpha(1.0)
        self.iconWidget:SetDesaturated(false)
        self.iconWidget:SetAlert(true)
        self.iconWidget.cooldown:Clear()
        
        -- High urgency sound alert
        if data and data.urgency and data.urgency >= 0.8 then
            if RA.db and RA.db.profile.interrupt and RA.db.profile.interrupt.soundAlert then
                PlaySound(SOUNDKIT.RAID_WARNING)
            end
        end
    end
    
    self.container:Show()
end

---Dismiss the interrupt alert.
function InterruptAlert:Dismiss()
    if not self.container:IsShown() then return end
    self.activeSpell = nil
    self.iconWidget:SetAlert(false)
    self.iconWidget:Clear()
    self.container:Hide()
end
