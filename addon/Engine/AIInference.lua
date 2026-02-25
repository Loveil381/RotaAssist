------------------------------------------------------------------------
-- RotaAssist - AI Inference Engine
-- Signal-based smart analysis engine.
-- Deduces combat phases, target counts, resources, and burst windows
-- based on observational signals from the environment.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local AIInference = {}
RA:RegisterModule("AIInference", AIInference)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

local THROTTLE_SIGNALS = 0.2
local THROTTLE_INFER   = 0.3
local HISTORY_SIZE     = 20
local MAX_NAMEPLATES   = 40

-- Persistent signal buffers
local pastCasts = {}
local castIndex = 1
local numPastCasts = 0

local lastSignalTime = 0
local lastInferTime  = 0
local sessionStartTime = 0

-- Persistent contextual state output
AIInference.InferredState = {
    targetCount = 1,
    timeSincePull = 0,
    blizzardRecommendation = 0,
    lastBlizzardChange = 0,
    
    inferred = {
        combatPhase = "NORMAL",
        phaseConfidence = 0.0,
        resourceState = "UNKNOWN",
        resourceConfidence = 0.0,
        burstActive = false,
        burstConfidence = 0.0,
        aoeActive = false,
        aoeConfidence = 0.0,
        nextBurstIn = -1,
        tip = nil
    }
}

-- Previously inferred states to detect transitions
local prevRec = 0
local prevAoeActive = false

-- Throttle tip generation to avoid spamming the same type of tip rapidly
local tipCooldowns = {}
local ACTIVE_TIP = nil

------------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------------

---Check if an array contains a value
---@param array table
---@param val any
---@return boolean
local function ArrayContains(array, val)
    if not array then return false end
    for _, v in ipairs(array) do
        if v == val then return true end
    end
    return false
end

---Get the active inference rules for the current spec.
---@return table|nil
local function GetInferenceRules()
    local specDetector = RA:GetModule("SpecDetector")
    if not specDetector then return nil end
    local currentSpec = specDetector:GetCurrentSpec()
    if not currentSpec then return nil end
    local specData = RA.SpecEnhancements[currentSpec.specID]
    if specData and specData.inferenceRules then
        return specData.inferenceRules
    end
    return nil
end

---Gets the count of hostile units with visible nameplates
---@return number count
local function CountNameplates()
    local count = 0
    -- Quick visible approximation. C_NamePlate.GetNamePlates() is more reliable,
    -- but this is combat-safe as a rough estimate.
    for i = 1, MAX_NAMEPLATES do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            -- Optional sanity check: range
            count = count + 1
        end
    end
    return math.max(1, count)
end

------------------------------------------------------------------------
-- Signal Collection (0.2s tick + event hooks)
------------------------------------------------------------------------

local function OnSpellCastSucceeded(_, unit, _, spellID)
    if unit ~= "player" or not InCombatLockdown() then return end
    
    -- Filter simplistic non-GCD spells using C_Spell
    local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, spellID)
    if not ok or type(cdInfo) ~= "table" then return end
    if spellID == 6603 then return end -- auto attack
    
    pastCasts[castIndex] = spellID
    castIndex = castIndex + 1
    if castIndex > HISTORY_SIZE then castIndex = 1 end
    numPastCasts = math.min(numPastCasts + 1, HISTORY_SIZE)
end

local function CollectSignals(now)
    local state = AIInference.InferredState
    
    if InCombatLockdown() then
        if sessionStartTime == 0 then sessionStartTime = now end
        state.timeSincePull = now - sessionStartTime
    else
        sessionStartTime = 0
        state.timeSincePull = 0
    end
    
    -- Sync nameplates
    state.targetCount = CountNameplates()
    
    -- Sync Blizzard recommendation
    local bridge = RA:GetModule("AssistedCombatBridge")
    if bridge then
        local rec = bridge:GetCurrentRecommendation()
        local nextSpell = (rec and rec.spellID) and rec.spellID or 0
        if nextSpell ~= state.blizzardRecommendation then
            prevRec = state.blizzardRecommendation
            state.blizzardRecommendation = nextSpell
            state.lastBlizzardChange = now
        end
    end
end

------------------------------------------------------------------------
-- State Inference (0.3s tick)
------------------------------------------------------------------------

local function InferAoEState(state, rules)
    -- Voting system
    local score = 0.0
    
    -- 1. Nameplate count is the strongest raw signal
    if state.targetCount >= 3 then
        score = score + 0.4
    elseif state.targetCount == 2 then
        score = score + 0.2
    end
    
    -- 2. What is Blizzard asking us to cast?
    if ArrayContains(rules.aoeSpells, state.blizzardRecommendation) then
        score = score + 0.3
    elseif ArrayContains(rules.singleTargetSpells, state.blizzardRecommendation) then
        score = score - 0.2
    end
    
    -- 3. What have we been casting?
    local recentAoECasts = 0
    local loopLimit = math.min(numPastCasts, 5) -- Look at last 5 casts
    local ptr = castIndex - 1
    for i = 1, loopLimit do
        if ptr < 1 then ptr = HISTORY_SIZE end
        local pastSpell = pastCasts[ptr]
        if ArrayContains(rules.aoeSpells, pastSpell) then
            recentAoECasts = recentAoECasts + 1
        end
        ptr = ptr - 1
    end
    
    if recentAoECasts >= 3 then
        score = score + 0.2
    end
    
    -- 4. Did Blizzard recently toggle from ST to AoE?
    if (state.lastBlizzardChange > GetTime() - 3.0) and 
       ArrayContains(rules.aoeSpells, state.blizzardRecommendation) and 
       ArrayContains(rules.singleTargetSpells, prevRec) then
        score = score + 0.1
    end
    
    score = math.max(0.0, math.min(1.0, score))
    state.inferred.aoeActive = score > 0.5
    state.inferred.aoeConfidence = score
end

local function InferBurstState(state, rules)
    local score = 0.0
    state.inferred.nextBurstIn = -1
    
    local burstSpell = rules.burstCooldownSpell
    if not burstSpell then
        state.inferred.burstActive = false
        state.inferred.burstConfidence = 0.0
        return
    end
    
    -- 1. Check native Cooldown data 
    local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, burstSpell)
    if ok and type(cdInfo) == "table" and cdInfo.duration then
        local elapsed = GetTime() - cdInfo.startTime
        local remaining = cdInfo.duration - elapsed
        
        if remaining > 0 and cdInfo.duration > 10 then 
            -- We are on cooldown for a major burst skill
            if elapsed < rules.burstDuration then
                -- Still within the burst window duration
                score = score + 0.95
            else
                -- Burst is over, we are waiting for CD
                if remaining < 5 then
                    state.inferred.nextBurstIn = remaining
                    -- We are NOT bursting yet, but we will soon
                    score = 0.0
                end
            end
        elseif remaining <= 0 then
            state.inferred.nextBurstIn = 0
        end
    end
    
    -- 2. Blizzard gave us a burst indicator spell (e.g., Death Sweep)
    if ArrayContains(rules.burstIndicatorSpells, state.blizzardRecommendation) then
        score = score + 0.95
    end
    
    -- 3. Recent memory
    local inMemory = false
    local loopLimit = math.min(numPastCasts, 5)
    local ptr = castIndex - 1
    for i = 1, loopLimit do
        if ptr < 1 then ptr = HISTORY_SIZE end
        if pastCasts[ptr] == burstSpell then
            inMemory = true
            break
        end
        ptr = ptr - 1
    end
    
    if inMemory then
        score = score + 0.90
    end
    
    score = math.max(0.0, math.min(1.0, score))
    state.inferred.burstActive = score > 0.6
    state.inferred.burstConfidence = score
end

local function InferResourceState(state, rules)
    local scoreHigh = 0.0
    local scoreLow  = 0.0
    
    -- Look at Blizzard recommendations to infer resource if we can't trust native HP bars
    -- (Though native power bars are combat-safe, analyzing recommendations ensures it aligns with rules)
    if ArrayContains(rules.generatorSpells, state.blizzardRecommendation) then
        scoreLow = scoreLow + 0.7
    elseif ArrayContains(rules.spenderSpells, state.blizzardRecommendation) then
        scoreHigh = scoreHigh + 0.6
    end
    
    if scoreLow > scoreHigh and scoreLow > 0.5 then
        state.inferred.resourceState = "LOW"
        state.inferred.resourceConfidence = scoreLow
    elseif scoreHigh > scoreLow and scoreHigh > 0.5 then
        state.inferred.resourceState = "HIGH"
        state.inferred.resourceConfidence = scoreHigh
    else
        state.inferred.resourceState = "UNKNOWN"
        state.inferred.resourceConfidence = 0.0
    end
end

local function InferCombatPhase(state)
    local inf = state.inferred
    -- Waterfall priority

    -- EMERGENCY: Inferred if Blizzard is recommending a defensive spell.
    -- 紧急情况：通过暴雪推荐防御技能推断（不读取 UnitHealth）。
    local isEmergency = false
    local rules = GetInferenceRules()
    if rules then
        local specDetector = RA:GetModule("SpecDetector")
        if specDetector then
            local spec = specDetector:GetCurrentSpec()
            if spec and RA.SpecEnhancements and RA.SpecEnhancements[spec.specID] then
                local defensives = RA.SpecEnhancements[spec.specID].defensives
                if defensives then
                    for _, def in ipairs(defensives) do
                        if state.blizzardRecommendation == def.spellID then
                            isEmergency = true
                            break
                        end
                    end
                end
            end
        end
    end

    if isEmergency then
        inf.combatPhase = "EMERGENCY"
        inf.phaseConfidence = 0.9
    elseif state.timeSincePull > 0 and state.timeSincePull < 6 then
        inf.combatPhase = "OPENER"
        inf.phaseConfidence = 0.8
    elseif inf.burstActive and inf.burstConfidence > 0.7 then
        inf.combatPhase = "BURST_ACTIVE"
        inf.phaseConfidence = inf.burstConfidence
    elseif inf.nextBurstIn > 0 and inf.nextBurstIn < 5 then
        inf.combatPhase = "BURST_PREPARE"
        inf.phaseConfidence = 0.85
    elseif inf.aoeActive and inf.aoeConfidence > 0.5 then
        inf.combatPhase = "AOE_MODE"
        inf.phaseConfidence = inf.aoeConfidence
    elseif inf.resourceState == "LOW" and inf.resourceConfidence > 0.6 then
        inf.combatPhase = "RESOURCE_STARVED"
        inf.phaseConfidence = inf.resourceConfidence
    elseif inf.resourceState == "HIGH" and inf.resourceConfidence > 0.6 then
        inf.combatPhase = "RESOURCE_CAP"
        inf.phaseConfidence = inf.resourceConfidence
    else
        inf.combatPhase = "NORMAL"
        inf.phaseConfidence = 1.0
    end
end

local function InferState()
    local state = AIInference.InferredState
    if not InCombatLockdown() then
        state.inferred.combatPhase = "NORMAL"
        state.inferred.tip = nil
        ACTIVE_TIP = nil
        prevAoeActive = false
        return
    end

    local rules = GetInferenceRules()
    if not rules then return end
    
    InferAoEState(state, rules)
    InferBurstState(state, rules)
    InferResourceState(state, rules)
    InferCombatPhase(state)
end

------------------------------------------------------------------------
-- Contextual Tip Generation (Smart Hints)
------------------------------------------------------------------------

local function GenerateTip(now)
    local state = AIInference.InferredState
    local inf = state.inferred
    local L = RA.L
    
    if not L then return end
    
    -- Clear expired active tip
    if ACTIVE_TIP and (now - ACTIVE_TIP.timestamp > ACTIVE_TIP.duration) then
        ACTIVE_TIP = nil
        inf.tip = nil
    end

    local potentialTips = {}
    
    -- 1. BURST PREPARATION
    if inf.combatPhase == "BURST_PREPARE" then
        if (not tipCooldowns["BURST"] or now - tipCooldowns["BURST"] > 15) then
            local burstIn = math.max(1, math.floor(inf.nextBurstIn))
            if inf.resourceState == "LOW" then
                table.insert(potentialTips, {
                    id = "BURST",
                    priority = 1,
                    type = "URGENT",
                    text = string.format(L["BURST_SOON_POOL_RESOURCE"], burstIn),
                    color = "ORANGE",
                    duration = 3
                })
            else
                table.insert(potentialTips, {
                    id = "BURST",
                    priority = 2,
                    type = "INFO",
                    text = L["BURST_READY"],
                    color = "GREEN",
                    duration = 3
                })
            end
        end
    end
    
    -- 2. AOE TOGGLE
    if inf.aoeActive and inf.aoeConfidence > 0.6 and not prevAoeActive then
        if (not tipCooldowns["AOE"] or now - tipCooldowns["AOE"] > 10) then
            table.insert(potentialTips, {
                id = "AOE",
                priority = 1,
                type = "PHASE_CHANGE",
                text = string.format(L["AOE_DETECTED"], state.targetCount),
                color = "BLUE",
                duration = 3
            })
        end
    end
    
    -- 3. SPECIFIC SKILL NOTES (e.g. Death Sweep during Meta)
    if inf.burstActive then
        if state.blizzardRecommendation == 210152 then -- Death Sweep
            if (not tipCooldowns["DEATH_SWEEP"] or now - tipCooldowns["DEATH_SWEEP"] > 20) then
                table.insert(potentialTips, {
                    id = "DEATH_SWEEP",
                    priority = 2,
                    type = "SKILL_NOTE",
                    text = L["DEATH_SWEEP_NOTE"],
                    color = "WHITE",
                    duration = 2
                })
            end
        end
    end
    
    -- 4. RESOURCE CAPPING
    if inf.resourceState == "HIGH" and inf.resourceConfidence > 0.7 then
        if (not tipCooldowns["RESOURCE"] or now - tipCooldowns["RESOURCE"] > 10) then
            table.insert(potentialTips, {
                id = "RESOURCE",
                priority = 1,
                type = "WARNING",
                text = L["RESOURCE_CAPPING"],
                color = "YELLOW",
                duration = 2
            })
        end
    end
    
    prevAoeActive = inf.aoeActive
    
    -- Select highest priority tip
    if #potentialTips > 0 then
        table.sort(potentialTips, function(a, b) return a.priority < b.priority end)
        local chosen = potentialTips[1]
        
        ACTIVE_TIP = {
            id = chosen.id,
            timestamp = now,
            duration = chosen.duration,
            tip = chosen
        }
        
        inf.tip = {
            text = chosen.text,
            type = chosen.type,
            color = chosen.color
        }
        
        tipCooldowns[chosen.id] = now
    end
end

------------------------------------------------------------------------
-- Update Loop
------------------------------------------------------------------------

local uiFrame = CreateFrame("Frame")
uiFrame:Hide()

uiFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    
    if (now - lastSignalTime) > THROTTLE_SIGNALS then
        CollectSignals(now)
        lastSignalTime = now
    end
    
    if (now - lastInferTime) > THROTTLE_INFER then
        InferState()
        GenerateTip(now)
        lastInferTime = now
    end
end)

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Returns the AI Inference payload payload
---@return table Context
function AIInference:GetContext()
    return self.InferredState
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function AIInference:OnInitialize()
    -- Ready
end

function AIInference:OnEnable()
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("PLAYER_REGEN_DISABLED", "AIInference", function()
            -- Reset memory on pull
            pastCasts = {}
            castIndex = 1
            numPastCasts = 0
            sessionStartTime = GetTime()
            prevAoeActive = false
            tipCooldowns = {}
            
            uiFrame:Show()
        end)
        
        eh:Subscribe("PLAYER_REGEN_ENABLED", "AIInference", function()
            uiFrame:Hide()
            AIInference.InferredState.inferred.combatPhase = "NORMAL"
            AIInference.InferredState.inferred.tip = nil
            ACTIVE_TIP = nil
        end)
    end
    
    RA:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", OnSpellCastSucceeded)
    
    if InCombatLockdown() then
        sessionStartTime = GetTime()
        uiFrame:Show()
    end
end

function AIInference:OnDisable()
    uiFrame:Hide()
    RA:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end
