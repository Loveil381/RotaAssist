------------------------------------------------------------------------
-- RotaAssist - Interrupt Advisor
-- 打断提示器 / Interrupt Advisor
-- Provides interrupt reminders using ONLY non-secret data (enemy cast
-- tracking via nameplates/events, without branch logic on secret spellIDs).
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local InterruptAdvisor = {}
RA:RegisterModule("InterruptAdvisor", InterruptAdvisor)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

local interruptState = {
    available = false,
    cooldownRemaining = 0,
    shouldInterrupt = false,
    urgency = 0
}

local currentInterruptConfig = nil
local lastInterruptCastTime = 0

------------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------------

---Check if player's interrupt spell is ready.
---检查玩家的打断技能是否就绪。
---@return boolean isReady, number cdRemaining
local function CheckInterruptCooldown()
    if not currentInterruptConfig or not currentInterruptConfig.spellID then return false, 0 end
    local spellID = currentInterruptConfig.spellID
    local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, spellID)
    
    -- If API gives useful non-secret data:
    if ok and type(cdInfo) == "table" then
        if cdInfo.duration > 1.5 then
            local rem = cdInfo.duration - (GetTime() - cdInfo.startTime)
            if rem > 0 then return false, rem end
        end
        return true, 0
    end
    
    -- Fallback: Estimate from cast history
    local cooldown = currentInterruptConfig.cooldown or 15
    local elapsed = GetTime() - lastInterruptCastTime
    if elapsed < cooldown then
        return false, cooldown - elapsed
    end
    
    return true, 0
end

---Check if Blizzard is currently recommending the interrupt spell.
---检查暴雪目前是否推荐打断技能。
---@return boolean recommended
local function IsBlizzRecommendingInterrupt()
    if not currentInterruptConfig or not currentInterruptConfig.spellID then return false end
    local bridge = RA:GetModule("AssistedCombatBridge")
    if not bridge then return false end
    local rec = bridge:GetCurrentRecommendation()
    return rec and (rec.spellID == currentInterruptConfig.spellID) or false
end

------------------------------------------------------------------------
-- Core Event Handlers
------------------------------------------------------------------------

---Update state based on an enemy cast event.
---根据敌方施法事件更新状态。我们不比较任何 SECRET API 内容。
local function EvaluateInterruptNeed(unitTarget)
    if not unitTarget or unitTarget == "player" then return end
    
    if not currentInterruptConfig or not currentInterruptConfig.spellID then return end
    
    if not RA.db or not RA.db.profile.interrupt or not RA.db.profile.interrupt.enabled then return end

    local isReady, cdRem = CheckInterruptCooldown()
    interruptState.available = isReady
    interruptState.cooldownRemaining = cdRem
    
    -- Strongest signal: Blizzard explicitly recommends it.
    local blizzSaysYes = IsBlizzRecommendingInterrupt()
    
    -- Heuristic signal: An enemy is casting, and our interrupt is ready.
    local enemyCasting = (UnitCastingInfo(unitTarget) ~= nil) or (UnitChannelInfo(unitTarget) ~= nil)

    if blizzSaysYes then
        interruptState.shouldInterrupt = true
        interruptState.urgency = 1.0
    elseif isReady and enemyCasting then
        interruptState.shouldInterrupt = true
        interruptState.urgency = 0.5
    else
        interruptState.shouldInterrupt = false
        interruptState.urgency = 0.0
    end

    if interruptState.shouldInterrupt then
        local eh = RA:GetModule("EventHandler")
        if eh then
            eh:Fire("ROTAASSIST_INTERRUPT_ALERT", true, {
                spellID = currentInterruptConfig.spellID,
                urgency = interruptState.urgency
            })
        end
    end
end

local function OnSpellCastSucceeded(_, unit, _, spellID)
    if unit == "player" and currentInterruptConfig and spellID == currentInterruptConfig.spellID then
        lastInterruptCastTime = GetTime()
        interruptState.available = false
        interruptState.shouldInterrupt = false
        interruptState.urgency = 0.0
        
        local eh = RA:GetModule("EventHandler")
        if eh then eh:Fire("ROTAASSIST_INTERRUPT_ALERT", false) end
    end
end

local function OnSpellCastStart(_, unitTarget)
    -- Fire and forget evaluate. We cannot read the secret spellID here.
    EvaluateInterruptNeed(unitTarget)
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get the latest non-secret interrupt state.
---获取最新的非机密打断状态。
---@return table {available, cooldownRemaining, shouldInterrupt, urgency}
function InterruptAdvisor:GetInterruptState()
    -- Perform an on-demand check of the cooldown and blizz recommendation
    local isReady, cdRem = CheckInterruptCooldown()
    interruptState.available = isReady
    interruptState.cooldownRemaining = cdRem
    
    if IsBlizzRecommendingInterrupt() then
        interruptState.shouldInterrupt = true
        interruptState.urgency = 1.0
    elseif not isReady then
        interruptState.shouldInterrupt = false
        interruptState.urgency = 0.0
    end
    
    return interruptState
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function InterruptAdvisor:OnInitialize()
    -- Nothing to setup explicitly here
end

function InterruptAdvisor:OnEnable()
    local function UpdateConfig()
        local sd = RA:GetModule("SpecDetector")
        if sd then
            local spec = sd:GetCurrentSpec()
            if spec and RA.SpecEnhancements[spec.specID] then
                local ehConfig = RA.SpecEnhancements[spec.specID]
                currentInterruptConfig = {
                    spellID = ehConfig.interruptSpellID or (ehConfig.interruptSpell and ehConfig.interruptSpell.spellID) or nil,
                    cooldown = ehConfig.interruptCooldown or 15
                }
            end
        end
    end

    UpdateConfig()

    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ROTAASSIST_SPEC_CHANGED", "InterruptAdvisor", UpdateConfig)
    end

    RA:RegisterEvent("UNIT_SPELLCAST_START", OnSpellCastStart)
    RA:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", OnSpellCastStart)
    RA:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", OnSpellCastSucceeded)
end

function InterruptAdvisor:OnDisable()
    RA:UnregisterEvent("UNIT_SPELLCAST_START")
    RA:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    RA:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end
