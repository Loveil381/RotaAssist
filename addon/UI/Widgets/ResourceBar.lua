------------------------------------------------------------------------
-- RotaAssist - Resource Bar Widget
-- A compact bar displaying current resource percentage and value.
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
    
    -- Fill Bar
    obj.fill = obj.bg:CreateTexture(nil, "ARTWORK")
    obj.fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    obj.fill:SetPoint("TOPLEFT", obj.bg, "TOPLEFT")
    obj.fill:SetPoint("BOTTOMLEFT", obj.bg, "BOTTOMLEFT")
    obj.fill:SetWidth(0.1) -- initial
    
    -- Text Overlay
    obj.text = obj.bg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    obj.text:SetPoint("CENTER", obj.bg, "CENTER", 0, 7) -- slightly above the bar
    obj.text:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    
    obj.width = width
    obj.currentColor = {r = 0.5, g = 0.5, b = 0.5} -- default gray
    
    return obj
end

---Get color scheme for power type.
---@param powerType number Enum.PowerType
---@return table {r, g, b}
local function getPowerTypeBaseColor(powerType)
    if powerType == 17 then -- Fury
        return {r=0.6, g=0.2, b=0.8}
    elseif powerType == 0 then -- Mana
        return {r=0.2, g=0.4, b=1.0}
    elseif powerType == 1 then -- Rage
        return {r=1.0, g=0.2, b=0.2}
    elseif powerType == 3 then -- Energy
        return {r=1.0, g=0.9, b=0.2}
    else
        return {r=0.5, g=0.5, b=0.5}
    end
end

---Update the resource bar display.
---@param current number
---@param max number
---@param powerType number|nil Enum.PowerType
function ResourceBar:Update(current, max, powerType)
    if not current or not max or max <= 0 then
        self.fill:SetWidth(0.1)
        self.text:SetText("")
        return
    end
    
    local pct = current / max
    if pct > 1 then pct = 1 end
    if pct < 0 then pct = 0 end
    
    -- Set width based on percentage
    local fillWidth = math.max(1, self.width * pct)
    self.fill:SetWidth(fillWidth)
    
    -- Text "current/max"
    self.text:SetText(string.format("%.0f/%.0f", current, max))
    
    -- Determine color based on thresholds
    local r, g, b = 0, 0, 0
    if pct < 0.3 then
        -- Low (Red)
        r, g, b = 0.9, 0.2, 0.2
    elseif pct < 0.6 then
        -- Med (Yellow)
        r, g, b = 0.9, 0.8, 0.1
    else
        -- High (Green)
        r, g, b = 0.2, 0.8, 0.2
    end
    
    -- Special case: base color override if not purely percentage-based
    if powerType == 17 then
        -- Fury: Purple-ish base, intensity varies
        r, g, b = 0.6 + (0.4 * pct), 0.2, 0.8
    elseif powerType == 0 then
        -- Mana: always blue
        r, g, b = 0.2, 0.4 + (0.4 * pct), 1.0
    end
    
    self.fill:SetVertexColor(r, g, b)
end
