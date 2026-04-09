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

-- 已知的被动/不可施放技能黑名单（API 查询的快速路径备份）
-- Known passive/non-castable spell blacklist (fast-path backup for API queries)
local PASSIVE_BLACKLIST = RA.Registry.PASSIVE_BLACKLIST

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
local metaExpireTime = 0

local META_SPELL_IDS
local WINDOW_TRIGGER_SPELLS
local WINDOW_STEP_DURATIONS

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

local function splitConditions(condition)
    local clauses = {}
    local normalized = condition:gsub("%s+AND%s+", "\1")
    for clause in normalized:gmatch("[^\1]+") do
        clauses[#clauses + 1] = trim(clause)
    end
    return clauses
end

local function compareNumber(lhs, op, rhs)
    if op == ">=" then
        return lhs >= rhs
    elseif op == "<=" then
        return lhs <= rhs
    elseif op == ">" then
        return lhs > rhs
    elseif op == "<" then
        return lhs < rhs
    elseif op == "==" then
        return lhs == rhs
    end
    return false
end

local function parseNumericCondition(cond, prefix)
    local suffix = trim(cond:gsub("^" .. prefix, "", 1))
    local operators = { ">=", "<=", "==", ">", "<" }

    for _, op in ipairs(operators) do
        if suffix:sub(1, #op) == op then
            local rawValue = trim(suffix:sub(#op + 1))
            local numericValue = tonumber(rawValue)
            if numericValue ~= nil then
                return op, numericValue
            end
            return nil, nil
        end
    end

    return nil, nil
end

local function getDefinitionSpellName(definitionInfo)
    if not definitionInfo then
        return nil
    end
    if definitionInfo.overrideName and definitionInfo.overrideName ~= "" then
        return definitionInfo.overrideName
    end
    if definitionInfo.spellID and C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, definitionInfo.spellID)
        if ok and info and info.name then
            return info.name
        end
    end
    return nil
end

local function setWindowState(simState, windowKey, active)
    simState.windows = simState.windows or {}
    simState.windowSteps = simState.windowSteps or {}
    simState.windows[windowKey] = active == true
    if active then
        simState.windowSteps[windowKey] = WINDOW_STEP_DURATIONS[windowKey] or 1
    else
        simState.windowSteps[windowKey] = 0
    end
end

local function tickWindowState(simState)
    if not simState.windowSteps then
        return
    end

    simState.windows = simState.windows or {}
    for windowKey, remainingSteps in pairs(simState.windowSteps) do
        if remainingSteps and remainingSteps > 0 then
            remainingSteps = remainingSteps - 1
            simState.windowSteps[windowKey] = remainingSteps
            if remainingSteps <= 0 then
                simState.windows[windowKey] = false
            end
        else
            simState.windows[windowKey] = false
        end
    end
end

local function getActiveTalentSpellNames()
    if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID then
        return {}
    end
    if not C_Traits or not C_Traits.GetConfigInfo or not C_Traits.GetTreeNodes
       or not C_Traits.GetNodeInfo or not C_Traits.GetEntryInfo or not C_Traits.GetDefinitionInfo then
        return {}
    end

    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then
        return {}
    end

    local okConfig, configInfo = pcall(C_Traits.GetConfigInfo, configID)
    if not okConfig or not configInfo or type(configInfo.treeIDs) ~= "table" then
        return {}
    end

    local names = {}
    for _, treeID in ipairs(configInfo.treeIDs) do
        local okNodes, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
        if okNodes and type(nodeIDs) == "table" then
            for _, nodeID in ipairs(nodeIDs) do
                local okNode, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                if okNode and nodeInfo and (nodeInfo.activeRank or 0) > 0 then
                    local activeEntryID = nodeInfo.activeEntry and nodeInfo.activeEntry.entryID
                    local entryIDs = activeEntryID and { activeEntryID } or nodeInfo.entryIDsWithCommittedRanks or nodeInfo.entryIDs
                    if type(entryIDs) == "table" then
                        for _, entryID in ipairs(entryIDs) do
                            local okEntry, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID)
                            if okEntry and entryInfo and entryInfo.definitionID then
                                local okDef, definitionInfo = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID)
                                if okDef then
                                    local spellName = getDefinitionSpellName(definitionInfo)
                                    if spellName then
                                        names[spellName] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return names
end

local function resolveProfileFromTalents(aplData)
    if not aplData or not aplData.profiles then
        return "default"
    end

    local activeTalentNames = getActiveTalentSpellNames()
    local hasAnyTalents = next(activeTalentNames) ~= nil
    if not hasAnyTalents then
        return currentProfileName or "default"
    end

    for profileName, profile in pairs(aplData.profiles) do
        if type(profile) == "table" and type(profile.signatureTalentNames) == "table" then
            for _, talentName in ipairs(profile.signatureTalentNames) do
                if activeTalentNames[talentName] then
                    return profileName
                end
            end
        end
    end

    return "default"
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

    local tokens = splitConditions(condition)

    for _, cond in ipairs(tokens) do
        cond = trim(cond)
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

        elseif cond:match("^not_after:(%d+)$") then
            local afterID = tonumber(cond:match("^not_after:(%d+)$"))
            pass = simState.lastCast ~= afterID

        elseif cond:match("^estimated_resource") then
            local op, value = parseNumericCondition(cond, "estimated_resource")
            if op and value then
                pass = compareNumber(simState.resource or 0, op, value)
            else
                pass = true
            end

        elseif cond:match("^target_count") then
            local op, value = parseNumericCondition(cond, "target_count")
            if op and value then
                pass = compareNumber(simState.targetCount or 1, op, value)
            else
                pass = true
            end

        elseif cond:match("^combat_time") then
            local op, value = parseNumericCondition(cond, "combat_time")
            if op and value then
                pass = compareNumber(simState.combatDuration or 0, op, value)
            else
                pass = true
            end

        elseif cond:match("^charges") then
            local op, value = parseNumericCondition(cond, "charges")
            if op and value then
                local charges = simState.charges and simState.charges[spellID] or 0
                pass = compareNumber(charges, op, value)
            else
                pass = true
            end

        elseif cond:match("^window:") then
            local windowKey = cond:match("^window:(.+)$")
            pass = simState.windows and simState.windows[windowKey] == true

        elseif cond:match("^not_window:") then
            local windowKey = cond:match("^not_window:(.+)$")
            pass = not (simState.windows and simState.windows[windowKey] == true)

        elseif cond == "not_in_meta" then
            pass = not simState.inMeta

        elseif cond == "in_meta" then
            pass = simState.inMeta == true

        else
            pass = false
        end

        if not pass then
            return false
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
    tickWindowState(simState)

    -- FIX (OverridePair): 降低 CD 阈值从 ≥8s 到 ≥3s，以正确模拟 Blade Dance/Death Sweep 等短 CD
    -- FIX (OverridePair): Lower threshold from ≥8s to ≥3s for proper short-CD simulation.
    -- Also set simulated CD on the paired override ID.
    -- 同时对覆盖对技能设置模拟 CD。
    local wsData = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
    if wsData and wsData.cdSeconds and wsData.cdSeconds >= 3 then
        simState.cooldowns[spellID] = wsData.cdSeconds
        -- FIX (OverridePair): mirror sim CD to paired spell
        local pairedID = RA.KNOWN_OVERRIDE_PAIRS and RA.KNOWN_OVERRIDE_PAIRS[spellID]
        if pairedID then
            simState.cooldowns[pairedID] = wsData.cdSeconds
        end
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

    if META_SPELL_IDS[spellID] then
        simState.inMeta = true
    end

    local triggeredWindow = WINDOW_TRIGGER_SPELLS[spellID]
    if triggeredWindow then
        setWindowState(simState, triggeredWindow, true)
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
    limitedState.combatDuration = limitedState.combatDuration or 0
    limitedState.charges = limitedState.charges or {}
    limitedState.windows = limitedState.windows or {}

    -- Build simulation state from the limited observable state
    local simState = {
        cooldowns   = {},
        resource    = limitedState.resource,
        inMeta      = limitedState.inMeta or metaActive,
        lastCast    = nil,
        targetCount = limitedState.targetCount,
        combatDuration = limitedState.combatDuration,
        charges = limitedState.charges,
        windows = limitedState.windows,
        windowSteps = {},
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

    for windowKey, active in pairs(limitedState.windows) do
        if active then
            simState.windowSteps[windowKey] = WINDOW_STEP_DURATIONS[windowKey] or 1
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
            -- FIX (Perf): build the step-note string ONCE per outer loop iteration,
            -- not once per rule in the inner loop, to avoid repeated string allocation.
            local stepNote = "APL prediction step " .. step

            local found = false
            for _, rule in ipairs(actionList) do
                -- Step 1: skip the spell Blizzard is already showing in slot 1 (only when a recommendation exists).
                -- Step 2+: allow repeated spells so builder-spam is predicted correctly.
                -- currentSpellID が nil の場合はスキップしない
                -- FIX: 始终允许预测重复技能，确保 Builder (如 喷发) 预测连续性
                local skipCurrent = false
                -- 跳过未学习的天赋技能 / Skip unlearned talent spells
                local notKnown = IsPlayerSpell and not IsPlayerSpell(rule.spellID)
                -- Step 1 only: real-time CD guard — if CooldownOverlay says this spell has
                -- > 1.0s remaining, skip it even if simState thinks it's ready.
                -- 仅第一步：实时 CD 检查，对 simState 的 CD 估算做最终安全网
                -- FIX (OverridePair): Also check paired override ID in real CD guard.
                -- 覆盖对实时 CD 检查：同时检查配对 ID 的 CD 状态。
                local realCD = false
                if not skipCurrent and not notKnown then
                    local cdOverlay = RA:GetModule("CooldownOverlay")
                    if cdOverlay then
                        local cds = cdOverlay:GetCooldownStates()
                        local cdState = cds[rule.spellID]
                        if cdState and not cdState.ready
                           and cdState.remaining and cdState.remaining > 1.0 then
                            if step == 1 then
                                realCD = true
                            else
                                -- Step 2+: 仅当 simState 也认为该技能在 CD 时才拒绝（避免过度过滤）
                                -- Trust simulation for future steps, but cross-check with reality
                                local simCD = simState.cooldowns[rule.spellID]
                                if simCD and simCD > 0 then
                                    realCD = true
                                end
                            end
                        end
                        -- Check paired override ID
                        if not realCD then
                            local pairedID = RA.KNOWN_OVERRIDE_PAIRS and RA.KNOWN_OVERRIDE_PAIRS[rule.spellID]
                            if pairedID then
                                local pairedState = cds[pairedID]
                                if pairedState and not pairedState.ready
                                   and pairedState.remaining and pairedState.remaining > 1.0 then
                                    if step == 1 then
                                        realCD = true
                                    else
                                        local simCD = simState.cooldowns[pairedID]
                                        if simCD and simCD > 0 then
                                            realCD = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                -- Step 1 only: soft-block guard — suppress recently-cast spells until
                -- SPELL_UPDATE_COOLDOWN confirms the real CD has started.
                -- 仅第一步：软屏蔽守卫，抑制刚施放的技能直到 SPELL_UPDATE_COOLDOWN 确认真实 CD
                local isSoftBlocked = false
                if step == 1 and limitedState.softBlocked then
                    local blockExpiry = limitedState.softBlocked[rule.spellID]
                    if blockExpiry and GetTime() < blockExpiry then
                        isSoftBlocked = true
                    end
                end

                -- Skip passive spells (e.g. Demon Blades 203555)
                -- 跳过被动技能（如恶魔之刃 203555）
                local isPassive = PASSIVE_BLACKLIST[rule.spellID] or (RA.IsSpellPassive and RA:IsSpellPassive(rule.spellID))

                -- 【新增】覆盖型被动检测：防止天赋覆盖变成被动（如 丝缕交织）
                local isOverriddenPassive = false
                if not isPassive and RA.ResolveSpellOverride then
                    local resolved, wasOvr = RA:ResolveSpellOverride(rule.spellID)
                    if wasOvr and RA:IsSpellPassive(resolved) then
                        isOverriddenPassive = true
                    end
                end

                if not skipCurrent and not notKnown and not isPassive and not isOverriddenPassive and not realCD and not isSoftBlocked
                   and self:EvaluateCondition(rule.condition, rule.spellID, simState) then
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
    currentProfileName = resolveProfileFromTalents(aplData)

    -- 预排序所有 action lists
    if aplData and aplData.profiles then
        for _, profile in pairs(aplData.profiles) do
            if profile.singleTarget then
                table.sort(profile.singleTarget, function(a,b) return (a.priority or 999) < (b.priority or 999) end)
            end
            if profile.aoe then
                table.sort(profile.aoe, function(a,b) return (a.priority or 999) < (b.priority or 999) end)
            end
        end
    end
    if aplData and aplData.rules then
        table.sort(aplData.rules, function(a,b) return (a.priority or 999) < (b.priority or 999) end)
    end

    RA:PrintDebug(string.format("APLEngine: Loaded APL for specID %d classID %s",
        specID, tostring(classID)))
end

---Re-evaluate the active profile based on the player's current talents.
---@return string profileName
function APLEngine:RefreshProfileFromTalents()
    if not currentAPL then
        currentProfileName = "default"
        return currentProfileName
    end
    currentProfileName = resolveProfileFromTalents(currentAPL)
    return currentProfileName
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
META_SPELL_IDS = {
    [191427] = 24,
    [198013] = 8,
    [187827] = 15,  -- Vengeance Metamorphosis
    [442508] = 20,  -- Devourer Void Metamorphosis
}

WINDOW_TRIGGER_SPELLS = {
    [198013] = "demonic",
    [191427] = "demonic",
    [258860] = "essence_break",
}

WINDOW_STEP_DURATIONS = {
    demonic = 4,
    essence_break = 2,
}

---Auto-activate meta state when the player casts a meta-trigger spell,
---then deactivate after the spell duration elapses.
---@param spellID number
function APLEngine:SetMetaStateFromCast(spellID)
    local duration = META_SPELL_IDS[spellID]
    if not duration then return end
    metaActive = true
    local newExpiry = GetTime() + duration
    -- Only update if this extends the current meta window
    if newExpiry > metaExpireTime then
        metaExpireTime = newExpiry
    end
    C_Timer.After(duration, function()
        -- Only deactivate if no newer meta has extended the window
        if GetTime() >= metaExpireTime then
            metaActive = false
        end
    end)
end

---Set the active profile.
---@param profileName string
function APLEngine:SetProfile(profileName)
    currentProfileName = profileName or "default"
end

---@return string
function APLEngine:GetProfileName()
    return currentProfileName or "default"
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
