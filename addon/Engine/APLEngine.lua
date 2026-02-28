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
    -- FIX: 只有真正的长 CD 技能（≥8秒）才在模拟中设置冷却
    -- GCD 类技能（如 Chaos Strike、Blade Dance）的短冷却不应阻塞后续预测步骤
    -- FIX: Only long-CD spells (≥8 s) get a simulated cooldown entry.
    -- GCD-level short CDs must not block subsequent prediction steps.
    local wsData = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
    if wsData and wsData.cdSeconds and wsData.cdSeconds >= 8 then
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
---@param currentSpellID number|nil  The spell Blizzard is recommending NOW
---@param limitedState   table|nil   Observable state: { resource, cooldowns, inMeta, targetCount }
---@param depth          number      How many steps ahead to predict (default 2)
---@return table[] predictions  Array of { spellID, confidence, source, note }
function APLEngine:PredictNext(currentSpellID, limitedState, depth)
    depth = depth or 2

    -- limitedState is still required for simulation; return early only if missing.
    -- currentSpellID may be nil (no Blizzard recommendation) — prediction continues from APL top.
    -- limitedState は必須。currentSpellID が nil の場合は APL 先頭から予測する。
    if not limitedState then return {} end

    if not currentAPL then return {} end

    -- FIX (P0-Bug2): Default-value protection for limitedState fields.
    -- Even when limitedState is provided, individual fields may be nil.
    limitedState.resource    = limitedState.resource or 0
    limitedState.cooldowns   = limitedState.cooldowns or {}
    limitedState.inMeta      = limitedState.inMeta or false
    limitedState.targetCount = limitedState.targetCount or 1

    -- Build simulation state from the limited observable state
    local simState = {
        cooldowns   = {},
        resource    = limitedState.resource,
        inMeta      = limitedState.inMeta or metaActive,
        lastCast    = nil,
        targetCount = limitedState.targetCount,
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

    -- Opener mode: 战斗开始前6秒内使用预定义的起手序列
    -- opener 序列优先级高于常规 APL 规则
    -- Opener mode: use the predefined pull sequence within the first 6 s of combat.
    -- This takes priority over the regular APL rule walk.
    local openerUsed = false
    if limitedState.combatDuration and limitedState.combatDuration < 6 then
        local openerSeq = nil
        if currentAPL and currentAPL.profiles then
            local profile = currentAPL.profiles[currentProfileName]
                         or currentAPL.profiles["default"]
            if profile and profile.opener then
                openerSeq = profile.opener
            end
        end

        if openerSeq then
            -- 根据当前 Blizzard 推荐（slot 1）判断我们在 opener 的哪一步
            -- Determine which opener step we have reached based on Blizzard's slot-1 spell.
            local startStep = 1
            if currentSpellID then
                for _, entry in ipairs(openerSeq) do
                    if entry.spellID == currentSpellID then
                        startStep = entry.step + 1
                        break
                    end
                end
            end

            -- 从 startStep 开始填充预测（最多 depth 步）
            -- Fill predictions starting from startStep, up to depth entries.
            for i = startStep, math.min(startStep + depth - 1, #openerSeq) do
                local entry = openerSeq[i]
                -- Skip spells the player hasn't learned (e.g. untalented Essence Break)
                -- 跳过未学习的技能（如未天赋的精华爆裂）
                local known = (not IsPlayerSpell) or IsPlayerSpell(entry.spellID)
                if entry and known then
                    predictions[#predictions + 1] = {
                        spellID    = entry.spellID,
                        confidence = math.max(0.7, 0.95 - (i - startStep) * 0.1),
                        source     = "apl_opener",
                        note       = entry.note or ("Opener step " .. i),
                    }
                end
            end

            if #predictions > 0 then
                openerUsed = true
            end
        end
    end

    -- 如果 opener 已经填充了预测，跳过常规 APL 循环
    -- Skip the regular APL walk when the opener sequence has provided predictions.
    if not openerUsed then
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
                -- Step 1: skip the spell Blizzard is already showing in slot 1 (only when a recommendation exists).
                -- Step 2+: allow repeated spells so builder-spam is predicted correctly.
                -- currentSpellID が nil の場合はスキップしない
                local skipCurrent = (step == 1 and currentSpellID and rule.spellID == currentSpellID)
                -- 跳过未学习的天赋技能 / Skip unlearned talent spells
                local notKnown = IsPlayerSpell and not IsPlayerSpell(rule.spellID)
                if not skipCurrent and not notKnown and self:EvaluateCondition(rule.condition, rule.spellID, simState) then
                    -- Confidence degrades with depth
                    local conf = math.max(0.5, 0.9 - (step - 1) * 0.2)

                    predictions[#predictions + 1] = {
                        spellID    = rule.spellID,
                        confidence = rule.confidence and math.min(rule.confidence, conf) or conf,
                        source     = "apl_predict",
                        note       = rule.note or stepNote,
                    }

                    -- Advance the simulation state
                    self:SimulateSpellCast(simState, rule.spellID)
                    found = true
                    break
                end
            end
            if not found then break end  -- no more valid spells
        end
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

-- Havoc Metamorphosis (191427) and Devourer Void Eruption (198013) active durations
local META_SPELL_IDS = { [191427] = 24, [198013] = 8 }

---Auto-activate meta state when the player casts a meta-trigger spell,
---then deactivate after the spell duration elapses.
---@param spellID number
function APLEngine:SetMetaStateFromCast(spellID)
    local duration = META_SPELL_IDS[spellID]
    if not duration then return end
    metaActive = true
    C_Timer.After(duration, function()
        metaActive = false
    end)
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
