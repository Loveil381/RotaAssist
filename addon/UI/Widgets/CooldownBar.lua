------------------------------------------------------------------------
-- RotaAssist - CooldownBar Widget
-- Horizontal bar containing multiple IconWidgets for major cooldown tracking.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.UI = RA.UI or {}
RA.UI.CooldownBar = {}
local CooldownBar = RA.UI.CooldownBar
CooldownBar.__index = CooldownBar

---Create a new CooldownBar.
---@param parent table
---@param maxIcons number (e.g. 5)
---@return table widget
function CooldownBar:Create(parent, maxIcons)
    local obj = setmetatable({}, self)
    
    obj.frame = CreateFrame("Frame", nil, parent)
    -- Initial placeholder size
    obj.frame:SetSize(1, 28)
    
    obj.maxIcons = maxIcons or 5
    obj.iconSize = 28
    obj.spacing = 4
    
    obj.icons = {}
    for i = 1, obj.maxIcons do
        local icon = RA.UI.IconWidget:Create(obj.frame, obj.iconSize)
        if i == 1 then
            icon.frame:SetPoint("LEFT", obj.frame, "LEFT", 0, 0)
        else
            icon.frame:SetPoint("LEFT", obj.icons[i-1].frame, "RIGHT", obj.spacing, 0)
        end
        icon.frame:Hide()
        obj.icons[i] = icon
    end
    
    return obj
end

---Update the cooldowns shown in the bar.
---@param cooldownStates table[] (Array from RecommendationManager)
function CooldownBar:Update(cooldownStates)
    if not cooldownStates or #cooldownStates == 0 then
        for i = 1, self.maxIcons do self.icons[i].frame:Hide() end
        self.frame:SetWidth(1)
        return
    end
    
    local numVisible = 0
    
    for i = 1, self.maxIcons do
        local icon = self.icons[i]
        local state = cooldownStates[i]
        
        if state then
            icon:SetSpell(state.spellID, state.texture)
            
            if state.ready then
                icon:SetCooldown(nil, nil)
                icon:SetDesaturated(false)
                icon:SetAlert(false)
                -- 就绪时显示 "OK" 表示大招可用
                -- Show "OK" when the cooldown is ready to use
                icon:SetKeybind("OK")
            else
                icon:SetDesaturated(true)
                local start = GetTime() - (state.duration and (state.duration - state.remaining) or 0)
                -- We only have remaining time easily available; to properly set Cooldown sweep
                -- we need duration. The Overlay passes 'remaining', let's fix it by passing start/dur
                -- or just fallback to desaturated without sweep if dur is missing.
                -- RecommendationManager actually provides 'remaining', let's assume duration is 60s fallback
                -- if not provided, or better, CooldownOverlay should send start/dur. 
                -- Assuming start and duration are injected or we just wait for CD alert.
                if state.startTime and state.duration then
                    icon:SetCooldown(state.startTime, state.duration)
                else
                    -- Approximate if only remaining is given
                    local approxDur = state.remaining > 0 and state.remaining or 1
                    icon:SetCooldown(GetTime() - (approxDur - state.remaining), approxDur)
                end
                
                -- 显示冷却剩余秒数文字
                -- Display remaining cooldown time text
                local remaining = state.remaining or 0
                if remaining > 0 then
                    if remaining >= 60 then
                        icon:SetKeybind(string.format("%dm", math.floor(remaining / 60)))
                    else
                        icon:SetKeybind(string.format("%d", math.ceil(remaining)))
                    end
                else
                    icon:SetKeybind("")
                end
                
                if state.remaining > 0 and state.remaining <= 5 then
                    icon:SetAlert(true)
                else
                    icon:SetAlert(false)
                end
            end
            
            icon.frame:Show()
            numVisible = numVisible + 1
        else
            icon.frame:Hide()
        end
    end
    
    -- Center align by setting dynamic width
    if numVisible > 0 then
        local totalWidth = (numVisible * self.iconSize) + ((numVisible - 1) * self.spacing)
        self.frame:SetWidth(totalWidth)
    else
        self.frame:SetWidth(1)
    end
end
