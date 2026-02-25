------------------------------------------------------------------------
-- RotaAssist - AccuracyMeter Widget
-- 准确率指示灯 / Accuracy Meter UI
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

if not RA.UI then RA.UI = {} end

local RA_AccuracyMeter = {}
RA_AccuracyMeter.__index = RA_AccuracyMeter

---Create a new AccuracyMeter widget.
---@param parent frame
---@param width number
---@param height number
---@return table
function RA_AccuracyMeter:Create(parent, width, height)
    width = width or 120
    height = height or 14

    local widget = setmetatable({}, self)

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)
    widget.frame = frame

    -- Background
    local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    bg:SetAllPoints()
    bg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    bg:SetBackdropColor(0, 0, 0, 0.6)
    bg:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
    widget.bg = bg

    -- StatusBar
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(100)
    widget.bar = bar

    -- Label
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 1)
    text:SetText("100%")
    widget.text = text

    -- Icon (Optional, anchor left)
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(height, height)
    icon:SetPoint("RIGHT", frame, "LEFT", -4, 0)
    icon:SetTexture("Interface\\Icons\\Achievement_BG_trueAVshutout")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    widget.icon = icon

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
    widget.mode = "smart"

    return widget
end

---Update the accuracy value smoothly.
---@param accuracy number 0 to 100
function RA_AccuracyMeter:Update(accuracy)
    if not accuracy then accuracy = 0 end
    accuracy = math.max(0, math.min(100, accuracy))
    
    self.bar:SetValue(accuracy)
    
    -- Color rules
    if accuracy >= 80 then
        self.bar:SetStatusBarColor(0.2, 0.8, 0.2) -- Green
    elseif accuracy >= 60 then
        self.bar:SetStatusBarColor(0.9, 0.8, 0.1) -- Yellow
    else
        self.bar:SetStatusBarColor(0.9, 0.2, 0.2) -- Red
    end

    local suffix = self.mode == "smart" and "S" or "B"
    self.text:SetText(string.format("%d%% (%s)", math.floor(accuracy), suffix))
end

---Set the display mode ("smart" or "blizzard").
---@param mode string
function RA_AccuracyMeter:SetMode(mode)
    self.mode = mode == "blizzard" and "blizzard" or "smart"
end

function RA_AccuracyMeter:Show()
    if self.isVisible then return end
    self.isVisible = true
    self.agHide:Stop()
    self.agShow:Play()
end

function RA_AccuracyMeter:Hide()
    if not self.isVisible then return end
    self.isVisible = false
    self.agShow:Stop()
    self.agHide:Play()
end

RA.UI.AccuracyMeter = RA_AccuracyMeter
