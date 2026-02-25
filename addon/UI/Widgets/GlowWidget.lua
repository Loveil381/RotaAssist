------------------------------------------------------------------------
-- RotaAssist - Glow Widget
-- Fallback for ActionButton_ShowOverlayGlow using AnimationGroup.
-- animates a golden border around the frame.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.UI = RA.UI or {}
RA.UI.GlowWidget = {}

local activeGlows = {}

---Create a single edge texture for the glow.
---@param parent table
---@return table texture
local function createEdgeTexture(parent)
    local tex = parent:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    -- Golden yellow, initial alpha 0
    tex:SetVertexColor(1, 0.82, 0, 0)
    return tex
end

---Initialize the glow elements on a given frame.
---@param frame table
---@return table glowData
local function initGlow(frame)
    local glowData = {}
    
    -- Create the container frame so it sits exactly over the target frame
    local container = CreateFrame("Frame", nil, frame)
    container:SetAllPoints(frame)
    container:SetFrameLevel(frame:GetFrameLevel() + 5)
    
    local thickness = 2

    glowData.top = createEdgeTexture(container)
    glowData.top:SetPoint("TOPLEFT", container, "TOPLEFT", -thickness, thickness)
    glowData.top:SetPoint("BOTTOMRIGHT", container, "TOPRIGHT", thickness, 0)

    glowData.bottom = createEdgeTexture(container)
    glowData.bottom:SetPoint("TOPLEFT", container, "BOTTOMLEFT", -thickness, 0)
    glowData.bottom:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", thickness, -thickness)

    glowData.left = createEdgeTexture(container)
    glowData.left:SetPoint("TOPLEFT", container, "TOPLEFT", -thickness, 0)
    glowData.left:SetPoint("BOTTOMRIGHT", container, "BOTTOMLEFT", 0, 0)

    glowData.right = createEdgeTexture(container)
    glowData.right:SetPoint("TOPLEFT", container, "TOPRIGHT", 0, 0)
    glowData.right:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", thickness, 0)

    -- Animation Group
    glowData.animGroup = container:CreateAnimationGroup()
    glowData.animGroup:SetLooping("REPEAT")

    -- Alpha animation: 0.4 -> 1.0 -> 0.4
    local alpha1 = glowData.animGroup:CreateAnimation("Alpha")
    alpha1:SetFromAlpha(0.4)
    alpha1:SetToAlpha(1.0)
    alpha1:SetDuration(0.4)
    alpha1:SetOrder(1)

    local alpha2 = glowData.animGroup:CreateAnimation("Alpha")
    alpha2:SetFromAlpha(1.0)
    alpha2:SetToAlpha(0.4)
    alpha2:SetDuration(0.4)
    alpha2:SetOrder(2)
    
    glowData.container = container
    return glowData
end

---Start the golden glow animation on a frame.
---@param frame table
function RA.UI.GlowWidget:Start(frame)
    if not frame then return end
    
    local glow = activeGlows[frame]
    if not glow then
        glow = initGlow(frame)
        activeGlows[frame] = glow
    end
    
    glow.container:Show()
    if not glow.animGroup:IsPlaying() then
        glow.animGroup:Play()
    end
end

---Stop and hide the glow animation on a frame.
---@param frame table
function RA.UI.GlowWidget:Stop(frame)
    if not frame then return end
    
    local glow = activeGlows[frame]
    if glow then
        glow.animGroup:Stop()
        glow.container:Hide()
    end
end
