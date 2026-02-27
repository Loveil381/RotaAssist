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

    -- WOW 12.0 SECRET VALUE SAFE
    local remaining, ready = RA:GetSpellCooldownSafe(spellID)
    if remaining ~= nil then
        if remaining > 0 then return false, remaining end
        return true, 0
    end

    -- Fallback: 通过施法历史估算
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
    -- 最强信号：暴雪明确推荐打断。
    local blizzSaysYes = IsBlizzRecommendingInterrupt()

    -- Heuristic signal: An enemy is casting and our interrupt is ready.
    -- 启发式信号：敌方正在施法且打断技能就绪。
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
            -- Fetch cooldown timing via the WoW 12.0 secret-value-safe wrapper.
            -- 通过 WoW 12.0 安全封装获取冷却计时数据。
            -- Returns: remaining, ready, cdStart, cdDuration  (nil on secret value)
            local _, _, cdStart, cdDuration = RA:GetSpellCooldownSafe(currentInterruptConfig.spellID)

            -- Build event payload; only include CD fields when the API returned
            -- real values (non-nil means no secret-value violation).
            -- 仅在 API 返回真实值时才附加冷却字段（nil 表示触发了 secret value 保护）。
            local payload = {
                spellID   = currentInterruptConfig.spellID,
                urgency   = interruptState.urgency,
                onCooldown = not isReady,  -- bool: interrupt is currently on CD / 打断技能当前是否在冷却
            }
            if cdStart ~= nil and cdDuration ~= nil then
                payload.startTime = cdStart
                payload.duration  = cdDuration
            end

            eh:Fire("ROTAASSIST_INTERRUPT_ALERT", true, payload)
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
        if eh then
            -- After a successful cast the spell is now on cooldown. Query the
            -- freshly-started cooldown so MainDisplay can start the spinner.
            -- 成功施法后技能进入冷却，立即查询以便 MainDisplay 启动转圈动画。
            local _, _, cdStart, cdDuration = RA:GetSpellCooldownSafe(currentInterruptConfig.spellID)

            local payload = {
                spellID    = currentInterruptConfig.spellID,
                urgency    = 0.0,
                onCooldown = true,  -- just cast → definitely on CD / 刚施法完，必然在冷却中
            }
            if cdStart ~= nil and cdDuration ~= nil then
                payload.startTime = cdStart
                payload.duration  = cdDuration
            end

            -- Pass active=true so the icon stays visible and shows the CD sweep.
            -- 传 active=true 使图标保持显示并展示冷却转圈效果。
            eh:Fire("ROTAASSIST_INTERRUPT_ALERT", true, payload)
        end
    end
end

-- FIX (P0-Bug1): Event handlers now receive custom event names from EventHandler
-- instead of raw WoW events. The first arg is the custom event name; the second
-- is the unit token forwarded by the central dispatcher.
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

        -- FIX (P0-Bug1): Subscribe to centrally-dispatched custom events instead of
        -- calling RA:RegisterEvent() directly, which would OVERWRITE EventHandler's
        -- central dispatchers registered in EventHandler:OnEnable().
        eh:Subscribe("ROTAASSIST_SPELLCAST_START", "InterruptAdvisor", OnSpellCastStart)
        eh:Subscribe("ROTAASSIST_CHANNEL_START", "InterruptAdvisor", OnSpellCastStart)
        eh:Subscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "InterruptAdvisor", OnSpellCastSucceeded)
    end
end

function InterruptAdvisor:OnDisable()
    -- FIX (P0-Bug1): Unsubscribe from EventHandler's custom events instead of
    -- calling RA:UnregisterEvent() which would tear down EventHandler's central
    -- dispatchers and break other subscribers.
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Unsubscribe("ROTAASSIST_SPELLCAST_START", "InterruptAdvisor")
        eh:Unsubscribe("ROTAASSIST_CHANNEL_START", "InterruptAdvisor")
        eh:Unsubscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "InterruptAdvisor")
        eh:Unsubscribe("ROTAASSIST_SPEC_CHANGED", "InterruptAdvisor")
    end
end
