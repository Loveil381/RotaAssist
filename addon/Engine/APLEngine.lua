------------------------------------------------------------------------
-- RotaAssist - APL Engine (Refactored)
-- Role: APL state-machine SIMULATOR / prediction engine.
-- No longer the "real-time combat decider" — Blizzard's C_AssistedCombat
-- provides slot 1. This engine predicts steps 2-3 using existing APL
-- data as "pre-baked knowledge".
-- 役割変更: リアルタイム判定→APLベース予測シミュレーター
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local APLEngine = {}
RA:RegisterModule("APLEngine", APLEngine)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

---@type table|nil  Currently loaded APL definition
local currentAPL = nil

---@type number|nil
local currentSpecID = nil

---@type number|nil  Class ID (disambiguates Devourer specID 1480)
local currentClassID = nil

---@type string  Active profile name
local currentProfileName = "default"

---@type boolean  Metamorphosis / Void Meta state estimate
local metaActive = false

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local function splitStr(str, sep)
    local result = {}
    local pattern = "([^" .. sep:gsub(".", "%%%1") .. "]+)"
    for part in str:gmatch(pattern) do
        result[#result + 1] = part
    end
    return result
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

------------------------------------------------------------------------
-- Condition Evaluator (retained from Phase 2)
-- シミュレーション状態に対して条件を評価する
------------------------------------------------------------------------

---Evaluate a single condition string against a simulation state.
---@param condition string   e.g. "cd_ready AND not_in_meta"
---@param spellID  number
---@param simState table     Simulated state: { cooldowns, resource, inMeta, lastCast }
---@return boolean passes
function APLEngine:EvaluateCondition(condition, spellID, simState)
    if not condition or condition == "always" then
        return true
    end

    local tokens = splitStr(condition, " ")

    for _, cond in ipairs(tokens) do
        cond = trim(cond)
        if cond == "AND" then
            -- skip conjunction
        else
            local pass = false

            if cond == "cd_ready" or cond == "ready" then
                local cd = simState.cooldowns[spellID]
                pass = not cd or cd <= 0

            elseif cond == "always" then
                pass = true

            elseif cond:match("^cd_soon:(%d+%.?%d*)$") then
                local t = tonumber(cond:match("^cd_soon:(%d+%.?%d*)$")) or 0
                local cd = simState.cooldowns[spellID] or 0
                pass = cd <= t

            elseif cond:match("^after:(%d+)$") then
                local afterID = tonumber(cond:match("^after:(%d+)$"))
                pass = (simState.lastCast == afterID)

            elseif cond:match("^estimated_resource") then
                -- Check against simulated resource level
                local reqMatch = cond:match(">=%s*(%d+)")
                if reqMatch then
                    pass = (simState.resource or 0) >= tonumber(reqMatch)
                else
                    pass = true  -- permissive if can't parse
                end

            elseif cond == "not_in_meta" then
                pass = not simState.inMeta

            elseif cond == "in_meta" then
                pass = simState.inMeta == true

            else
                pass = false  -- unknown conditions fail safely in simulation
            end

            if not pass then return false end
        end
    end
    return true
end

------------------------------------------------------------------------
-- Simulation Engine
-- シミュレーションエンジン: 1回のキャスト結果を模擬する
------------------------------------------------------------------------

---Simulate casting a spell: update cooldowns, deduct/gain resource.
---@param simState table  Mutable simulation state
---@param spellID  number The spell being cast
---@return table simState  The updated state (same table, mutated)
function APLEngine:SimulateSpellCast(simState, spellID)
    -- Apply cooldown from WhitelistSpells
    local wsData = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
    if wsData and wsData.cdSeconds and wsData.cdSeconds > 0 then
        simState.cooldowns[spellID] = wsData.cdSeconds
    end

    -- Apply resource cost/gen from SpecEnhancements
    local enhData = currentSpecID and RA.SpecEnhancements and RA.SpecEnhancements[currentSpecID]
    if enhData and enhData.resource and enhData.resource.spellCosts then
        local costData = enhData.resource.spellCosts[spellID]
        if costData then
            if costData.cost then
                simState.resource = (simState.resource or 0) - costData.cost
                if simState.resource < 0 then simState.resource = 0 end
            end
            if costData.gen then
                simState.resource = (simState.resource or 0) + costData.gen
                local maxRes = enhData.resource.maxBase or 100
                if simState.resource > maxRes then simState.resource = maxRes end
            end
        end
    end

    simState.lastCast = spellID
    return simState
end

------------------------------------------------------------------------
-- Prediction: PredictNext()
-- 予測: Blizzardの推薦スペルから次の2ステップを予測する
------------------------------------------------------------------------

---Get the action list for the current profile and context.
---@param simState table
---@return table|nil actionList
local function getActionList(simState)
    if not currentAPL then return nil end

    if currentAPL.profiles then
        local profile = currentAPL.profiles[currentProfileName]
                     or currentAPL.profiles["default"]
        if profile then
            -- Devourer dual-phase
            if currentClassID == 12 and currentSpecID == 1480
                    and profile.voidMeta and simState.inMeta then
                return profile.voidMeta.singleTarget or profile.voidMeta
            end
            if simState.targetCount and simState.targetCount >= 3 and profile.aoe then
                return profile.aoe
            end
            return profile.singleTarget
        end
    end
    -- Phase 1 fallback
    return currentAPL.rules
end

---Predict the next N steps from a given starting spell.
---Slot 1 is always the Blizzard recommendation (not produced here).
---This returns steps 2..depth+1 for the UI.
---@param currentSpellID number  The spell Blizzard is recommending NOW
---@param limitedState   table   Observable state: { resource, cooldowns, inMeta, targetCount }
---@param depth          number  How many steps ahead to predict (default 2)
---@return table[] predictions  Array of { spellID, confidence, source, note }
function APLEngine:PredictNext(currentSpellID, limitedState, depth)
    depth = depth or 2
    if not currentAPL then return {} end

    -- Build simulation state from the limited observable state
    local simState = {
        cooldowns   = {},
        resource    = limitedState.resource or 0,
        inMeta      = limitedState.inMeta or metaActive,
        lastCast    = nil,
        targetCount = limitedState.targetCount or 1,
    }
    -- Copy cooldown data into simState
    if limitedState.cooldowns then
        for spellID, val in pairs(limitedState.cooldowns) do
            if type(val) == "table" then
                simState.cooldowns[spellID] = val.remaining or 0
            else
                simState.cooldowns[spellID] = val
            end
        end
    end

    -- Simulate casting the current Blizzard recommendation first
    if currentSpellID then
        self:SimulateSpellCast(simState, currentSpellID)
    end

    -- Now walk the APL to find the next `depth` spells
    local predictions = {}
    local usedSpells  = { [currentSpellID or 0] = true }

    for step = 1, depth do
        local actionList = getActionList(simState)
        if not actionList then break end

        -- Sort by priority
        local sorted = {}
        for _, rule in ipairs(actionList) do sorted[#sorted + 1] = rule end
        table.sort(sorted, function(a, b) return (a.priority or 999) < (b.priority or 999) end)

        -- FIX (Perf): build the step-note string ONCE per outer loop iteration,
        -- not once per rule in the inner loop, to avoid repeated string allocation.
        local stepNote = "APL prediction step " .. step

        local found = false
        for _, rule in ipairs(sorted) do
            if not usedSpells[rule.spellID] then
                if self:EvaluateCondition(rule.condition, rule.spellID, simState) then
                    -- Confidence degrades with depth
                    local conf = math.max(0.5, 0.9 - (step - 1) * 0.2)

                    predictions[#predictions + 1] = {
                        spellID    = rule.spellID,
                        confidence = rule.confidence and math.min(rule.confidence, conf) or conf,
                        source     = "apl_predict",
                        note       = rule.note or stepNote,
                    }
                    usedSpells[rule.spellID] = true

                    -- Advance the simulation state
                    self:SimulateSpellCast(simState, rule.spellID)
                    found = true
                    break
                end
            end
        end
        if not found then break end  -- no more valid spells
    end

    return predictions
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function APLEngine:OnInitialize() end
function APLEngine:OnEnable() end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Called by SpecDetector when a new spec loads or changes.
---@param specID  number
---@param aplData table  From RA.APLData[specID]
---@param classID number|nil
function APLEngine:SetAPL(specID, aplData, classID)
    currentSpecID      = specID
    currentClassID     = classID
    currentAPL         = aplData
    metaActive         = false
    currentProfileName = "default"
    RA:PrintDebug(string.format("APLEngine: Loaded APL for specID %d classID %s",
        specID, tostring(classID)))
end

---Notify the engine of Metamorphosis state.
---@param active boolean
function APLEngine:SetMetaState(active)
    metaActive = active == true
end

---@return boolean
function APLEngine:IsMetaActive()
    return metaActive
end

---Set the active profile.
---@param profileName string
function APLEngine:SetProfile(profileName)
    currentProfileName = profileName or "default"
end

---@return table|nil
function APLEngine:GetCurrentAPL()
    return currentAPL
end

---@return boolean
function APLEngine:HasAPL()
    return currentAPL ~= nil
end

function APLEngine:ClearAPL()
    currentAPL    = nil
    currentSpecID = nil
end
