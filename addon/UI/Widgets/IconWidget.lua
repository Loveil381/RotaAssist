------------------------------------------------------------------------
-- RotaAssist - Icon Widget
-- Encapsulates a single spell icon with cooldown, keybind, confidence,
-- and alert/glow overlay capabilities.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.UI = RA.UI or {}
RA.UI.IconWidget = {}
local IconWidget = RA.UI.IconWidget
IconWidget.__index = IconWidget

---Create a new Icon Widget.
---@param parent table   Parent frame
---@param size number    Width and height
---@param name string    Global name for the underlying frame (can be nil)
---@return table widget
function IconWidget:Create(parent, size, name)
    local obj = setmetatable({}, self)
    
    -- Base frame (Button so it can intercept clicks if needed, but not ActionButton)
    obj.frame = CreateFrame("Button", name, parent, "BackdropTemplate")
    obj.frame:SetSize(size, size)
    
    -- Icon Texture
    obj.icon = obj.frame:CreateTexture(nil, "ARTWORK")
    obj.icon:SetAllPoints(obj.frame)
    obj.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Zoom in slightly to remove default borders
    obj.icon:SetTexture(134400) -- Question mark fallback
    
    -- Cooldown Frame
    obj.cooldown = CreateFrame("Cooldown", nil, obj.frame, "CooldownFrameTemplate")
    obj.cooldown:SetAllPoints(obj.frame)
    obj.cooldown:SetDrawEdge(false)
    
    -- Keybind Text (Bottom Right)
    obj.keybind = obj.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    obj.keybind:SetPoint("TOPRIGHT", obj.frame, "TOPRIGHT", -1, -1)
    obj.keybind:SetJustifyH("RIGHT")
    local fontSize = math.max(10, math.floor(size * 0.25))
    obj.keybind:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    
    -- Confidence Text (Top Left)
    obj.confidence = obj.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    obj.confidence:SetPoint("BOTTOMLEFT", obj.frame, "BOTTOMLEFT", 2, 2)
    obj.confidence:SetJustifyH("LEFT")
    obj.confidence:SetFont(STANDARD_TEXT_FONT, math.max(10, math.floor(size * 0.22)), "OUTLINE")
    obj.confidence:SetTextColor(1, 0.8, 0) -- Gold
    
    -- Alert Frame (Red pulsating border)
    obj.alertFrame = CreateFrame("Frame", nil, obj.frame, "BackdropTemplate")
    obj.alertFrame:SetAllPoints(obj.frame)
    obj.alertFrame:SetFrameLevel(obj.frame:GetFrameLevel() + 2)
    obj.alertFrame:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    obj.alertFrame:SetBackdropBorderColor(1, 0.1, 0.1, 1)
    obj.alertFrame:Hide()
    
    obj.alertAnim = obj.alertFrame:CreateAnimationGroup()
    obj.alertAnim:SetLooping("REPEAT")
    local a1 = obj.alertAnim:CreateAnimation("Alpha")
    a1:SetFromAlpha(0.3)
    a1:SetToAlpha(1.0)
    a1:SetDuration(0.5)
    a1:SetOrder(1)
    local a2 = obj.alertAnim:CreateAnimation("Alpha")
    a2:SetFromAlpha(1.0)
    a2:SetToAlpha(0.3)
    a2:SetDuration(0.5)
    a2:SetOrder(2)
    
    -- Out of Range Animation
    obj.oorAnim = obj.frame:CreateAnimationGroup()
    obj.oorAnim:SetLooping("REPEAT")
    local o1 = obj.oorAnim:CreateAnimation("Alpha")
    o1:SetFromAlpha(0.4)
    o1:SetToAlpha(0.8)
    o1:SetDuration(0.4)
    o1:SetOrder(1)
    local o2 = obj.oorAnim:CreateAnimation("Alpha")
    o2:SetFromAlpha(0.8)
    o2:SetToAlpha(0.4)
    o2:SetDuration(0.4)
    o2:SetOrder(2)
    
    obj.currentSpellID = nil
    
    return obj
end

---Set the spell to display. Triggers crossfade if changed.
---@param spellID number
---@param texture number|nil
function IconWidget:SetSpell(spellID, texture)
    if self.currentSpellID == spellID then return end
    self.currentSpellID = spellID
    
    if not texture then
        local ok, info = pcall(C_Spell.GetSpellTexture, spellID)
        texture = (ok and info) and info or 134400
    end
    
    -- Crossfade
    UIFrameFadeOut(self.frame, 0.1)
    C_Timer.After(0.1, function()
        self.icon:SetTexture(texture)
        UIFrameFadeIn(self.frame, 0.1)
    end)
end

---Update the cooldown sweep.
---@param start number|nil
---@param duration number|nil
function IconWidget:SetCooldown(start, duration)
    if start and duration and duration > 1.5 then
        self.cooldown:SetCooldown(start, duration)
    else
        self.cooldown:Clear()
    end
end

---Set confidence stars (★★★, ★★☆, ★☆☆) or hide.
---@param level number|nil  3=high, 2=med, 1=low
function IconWidget:SetConfidence(level)
    if not level or level < 1 then
        self.confidence:SetText("")
    elseif level == 3 then
        self.confidence:SetText("★★★")
    elseif level == 2 then
        self.confidence:SetText("★★☆")
    else
        self.confidence:SetText("★☆☆")
    end
end

---Set the keybind text.
---@param text string|nil
function IconWidget:SetKeybind(text)
    if text and text ~= "" then
        self.keybind:SetText(text)
    else
        self.keybind:SetText("")
    end
end

---Toggle the primary recommendation glow.
---@param enabled boolean
function IconWidget:SetGlow(enabled)
    local ActionButton_ShowOverlayGlow = _G.ActionButton_ShowOverlayGlow
    local ActionButton_HideOverlayGlow = _G.ActionButton_HideOverlayGlow
    
    if enabled then
        if ActionButton_ShowOverlayGlow then
            ActionButton_ShowOverlayGlow(self.frame)
        else
            RA.UI.GlowWidget:Start(self.frame)
        end
    else
        if ActionButton_HideOverlayGlow then
            ActionButton_HideOverlayGlow(self.frame)
        end
        RA.UI.GlowWidget:Stop(self.frame)
    end
end

---Toggle the red alert pulse (for defensives / approaching CDs).
---@param enabled boolean
function IconWidget:SetAlert(enabled)
    if enabled then
        self.alertFrame:Show()
        if not self.alertAnim:IsPlaying() then self.alertAnim:Play() end
    else
        self.alertAnim:Stop()
        self.alertFrame:Hide()
    end
end

---Toggle out of range pulsing red state
---@param outOfRange boolean
function IconWidget:SetOutOfRange(outOfRange)
    if outOfRange then
        self.icon:SetVertexColor(0.8, 0.2, 0.2)
        if not self.oorAnim:IsPlaying() then self.oorAnim:Play() end
    else
        self.icon:SetVertexColor(1, 1, 1)
        if self.oorAnim:IsPlaying() then
            self.oorAnim:Stop()
            self.frame:SetAlpha(1.0)
        end
    end
end

---Apply desaturation (greyscale) to the icon.
---@param desaturated boolean
function IconWidget:SetDesaturated(desaturated)
    self.icon:SetDesaturated(desaturated)
end

---Clear the widget.
function IconWidget:Clear()
    self.currentSpellID = nil
    self.icon:SetTexture(134400)
    self.cooldown:Clear()
    self:SetKeybind("")
    self:SetConfidence(nil)
    self:SetGlow(false)
    self:SetAlert(false)
    self:SetOutOfRange(false)
    self:SetDesaturated(false)
end
