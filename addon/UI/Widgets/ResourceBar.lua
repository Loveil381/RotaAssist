------------------------------------------------------------------------
-- RotaAssist - Resource Bar Widget
-- A compact bar displaying current resource percentage and value.
-- WOW 12.0 SECRET VALUE SAFE: Uses StatusBar widget for in-combat
-- updates — StatusBar:SetValue() accepts secret values natively.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.UI = RA.UI or {}
RA.UI.ResourceBar = {}
local ResourceBar = RA.UI.ResourceBar
ResourceBar.__index = ResourceBar

---Create a new Resource Bar.
---@param parent table
---@param width number
---@param height number
---@return table widget
function ResourceBar:Create(parent, width, height)
    local obj = setmetatable({}, self)

    width = width or 48
    height = height or 8

    -- Background Bar
    obj.bg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    obj.bg:SetSize(width, height)
    obj.bg:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    obj.bg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    -- StatusBar (WOW 12.0 SECRET VALUE SAFE: SetValue accepts secrets)
    obj.statusBar = CreateFrame("StatusBar", nil, obj.bg)
    obj.statusBar:SetAllPoints(obj.bg)
    obj.statusBar:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
    obj.statusBar:SetMinMaxValues(0, 1)
    obj.statusBar:SetValue(0)

    -- Text Overlay
    obj.text = obj.bg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    obj.text:SetPoint("CENTER", obj.bg, "CENTER", 0, 7) -- slightly above the bar
    obj.text:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")

    obj.width = width
    obj.lastPowerType = nil

    return obj
end

---Get color scheme for power type.
---@param powerType number Enum.PowerType
---@return number r, number g, number b
local function getPowerTypeColor(powerType)
    if powerType == 17 then -- Fury
        return 0.6, 0.2, 0.8
    elseif powerType == 0 then -- Mana
        return 0.2, 0.4, 1.0
    elseif powerType == 1 then -- Rage
        return 1.0, 0.2, 0.2
    elseif powerType == 3 then -- Energy
        return 1.0, 0.9, 0.2
    elseif powerType == 8 then -- LunarPower (Astral Power)
        return 0.3, 0.5, 1.0
    elseif powerType == 11 then -- Maelstrom
        return 0.0, 0.5, 1.0
    elseif powerType == 4 then -- Combo Points
        return 1.0, 0.6, 0.0
    else
        return 0.5, 0.5, 0.5
    end
end

---Update the resource bar for non-secret values (out of combat).
---@param current number
---@param max number
---@param powerType number|nil Enum.PowerType
function ResourceBar:Update(current, max, powerType)
    if not current or not max or max <= 0 then
        self.statusBar:SetValue(0)
        self.text:SetText("")
        return
    end

    local pct = current / max
    if pct > 1 then pct = 1 end
    if pct < 0 then pct = 0 end

    self.statusBar:SetMinMaxValues(0, max)
    self.statusBar:SetValue(current)

    -- Text "current/max"
    self.text:SetText(string.format("%.0f/%.0f", current, max))

    -- Set color based on power type
    local r, g, b = getPowerTypeColor(powerType or -1)
    self.statusBar:SetStatusBarColor(r, g, b)
end

---WOW 12.0 SECRET VALUE SAFE: Update using secret-safe widget APIs.
---StatusBar:SetValue() and SetMinMaxValues() accept secret values natively.
---@param powerType number Enum.PowerType
function ResourceBar:UpdateSecretSafe(powerType)
    if not powerType then
        self.statusBar:SetValue(0)
        self.text:SetText("")
        return
    end

    local okCur, curPowerRaw = pcall(UnitPower, "player", powerType)
    local okMax, maxPowerRaw = pcall(UnitPowerMax, "player", powerType)

    local curPower = (okCur and curPowerRaw and not issecretvalue(curPowerRaw)) and curPowerRaw or 0
    local maxPower = (okMax and maxPowerRaw and not issecretvalue(maxPowerRaw) and maxPowerRaw > 0) and maxPowerRaw or 1

    local displayCur = (okCur and curPowerRaw) and curPowerRaw or 0

    self.statusBar:SetMinMaxValues(0, maxPower)
    self.statusBar:SetValue(displayCur)

    -- WOW 12.0 SECRET VALUE SAFE: Use string.format with secrets (produces secret string)
    self.text:SetText(string.format("%.0f/%.0f", displayCur, maxPower))

    -- Set color based on power type (non-secret color choice)
    if self.lastPowerType ~= powerType then
        local r, g, b = getPowerTypeColor(powerType)
        self.statusBar:SetStatusBarColor(r, g, b)
        self.lastPowerType = powerType
    end
end
