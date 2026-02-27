------------------------------------------------------------------------
-- RotaAssist - Smart Queue Manager
-- 智能队列管理器 / Smart Queue Manager
-- The final fusion layer combining Blizzard, APL, AI Inference,
-- Cooldowns, and Defensives into a single prioritized display queue.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local SmartQueueManager = {}
RA:RegisterModule("SmartQueueManager", SmartQueueManager)

------------------------------------------------------------------------
-- Configuration & Throttling
------------------------------------------------------------------------

local THROTTLE_UPDATE = 0.15

local defaultWeights = {
    blizzardWeight = 1.0,
    aplWeight      = 0.6,
    aiWeight       = 0.4,
    cdWeight       = 0.5,
    defWeight      = 0.8
}

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

local updateFrame = nil
local lastUpdate  = 0

-- Engine Module References (cached for speed)
local mBridge
local mAIInference
local mAPLEngine
local mCooldownOverlay
local mDefensiveAdvisor

-- Outputs (zero-allocation recycle)
local finalQueue = {
    main      = nil,
    next      = {},
    cooldowns = {},
    defensive = nil,
    phase     = "UNKNOWN",
    tip       = nil,
    accuracy  = 0,
    aiContext = nil -- Keep backward compatible with UI that reads aiContext
}

-- Previous main spell ID to fire event on change
local prevMainSpellID = nil

-- FIX (Bug2): Track last-frame main recommendation so AccuracyTracker
-- can compare the spell that was recommended *before* the cast completed.
-- 上一帧主推荐ID，供 AccuracyTracker 做上一帧比对。
local lastRecommendedSpellID = nil

------------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------------

---Calculate priority score for a spell candidate.
---计算候选技能的优先级得分。
---@param spellID number
---@param context table
---@param weights table
---@return number score, string source
local function CalculateScore(spellID, context, weights)
    local score = 0
    local primarySource = "UNKNOWN"

    -- 1. Blizzard Recommendation
    if context.blizzSpell == spellID then
        score = score + (1.0 * weights.blizzardWeight)
        primarySource = "BLIZZARD"
    end

    -- 2. APL Engine Prediction (first element of aplPredictions array)
    -- FIX (Bug1): aplPred is now the first element {spellID, confidence, source}
    -- 修复：aplPred 现在是 aplPredictions[1] 而不是整个数组
    if context.aplPred and context.aplPred.spellID == spellID then
        score = score + (context.aplPred.confidence * weights.aplWeight)
        if score > (1.0 * weights.blizzardWeight) then
            primarySource = "APL"
        end
    end

    -- 3. AI Inference Tip Bonus (no direct spellID map from tips; APL/Blizzard drive)
    if context.aiTip and context.aiTip.text then
        -- Simplified: no direct DB link; let APL/Blizzard drive mostly.
    end

    -- 4. Cooldown Overlay (whitelisted CDs ready during BURST prep)
    if context.cdReadyList[spellID] and context.aiPhase == "BURST_PREPARE" then
        score = score + (0.5 * weights.cdWeight)
    end

    -- 5. Defensive Urgency
    if context.defSpell == spellID then
        score = score + ((context.defUrgency or 1.0) * weights.defWeight)
        primarySource = "DEFENSIVE"
    end

    return score, primarySource
end

------------------------------------------------------------------------
-- Update Loop
------------------------------------------------------------------------

local function AssembleQueue()
    if not InCombatLockdown() and not (RA.db and RA.db.profile.display.showOutOfCombat) then
        finalQueue.main      = nil
        finalQueue.next      = {}
        finalQueue.cooldowns = {}
        finalQueue.defensive = nil
        return
    end

    local weights = RA.db and RA.db.profile.smartQueue or defaultWeights

    -- 1. Gather Context
    local context = {
        blizzSpell   = nil,
        aplPred      = nil,   -- first APL prediction {spellID, confidence, source}
        cdReadyList  = {},
        defSpell     = nil,
        defUrgency   = 0,
        aiPhase      = "NORMAL",
        aiTip        = nil
    }

    if mBridge then
        local rec = mBridge:GetCurrentRecommendation()
        context.blizzSpell = rec and rec.spellID or nil
    end

    -- FIX (Bug1): PredictNext returns an ARRAY of predictions.
    -- Parse it correctly; the first element joins scoring, rest go to next[].
    -- 修复：PredictNext 返回数组，第一个元素参与评分，其余填充 next[]。
    local aplPredictions = {}
    if mAPLEngine and mAPLEngine.HasAPL and mAPLEngine:HasAPL() then
        -- FIX (P0-Bug2): Build a valid limitedState table from context
        local limitedState = {
            resource    = 0,
            cooldowns   = {},
            inMeta      = false,
            targetCount = 1,
        }

        -- FIX (Bug4): Support both `type` and `powerType` field names in
        -- SpecEnhancements resource config.
        -- 修复：同时兼容 resource.type 和 resource.powerType 两种写法。
        local powerType = 0  -- default to mana
        local specDetector = RA:GetModule("SpecDetector")
        if specDetector then
            local spec = specDetector:GetCurrentSpec()
            if spec and RA.SpecEnhancements and RA.SpecEnhancements[spec.specID] then
                local resConfig = RA.SpecEnhancements[spec.specID].resource
                if resConfig then
                    powerType = resConfig.powerType or resConfig.type or 0
                end
            end
        end
        limitedState.resource = UnitPower("player", powerType) or 0

        -- Populate cooldowns from CooldownOverlay states
        if mCooldownOverlay then
            local cds = mCooldownOverlay:GetCooldownStates()
            for sid, cd in pairs(cds) do
                limitedState.cooldowns[sid] = cd.remaining or 0
            end
        end

        -- Populate inMeta from APLEngine state
        limitedState.inMeta = mAPLEngine:IsMetaActive()

        -- Populate targetCount from AIInference if available
        if mAIInference then
            local aiCtx = mAIInference:GetContext()
            if aiCtx and aiCtx.targetCount then
                limitedState.targetCount = aiCtx.targetCount
            end
        end

        local ok, result = pcall(mAPLEngine.PredictNext, mAPLEngine, context.blizzSpell, limitedState)
        if ok and type(result) == "table" then
            aplPredictions = result
        end
    end

    -- First APL prediction participates in scoring
    -- 第一个 APL 预测参与主推荐评分
    if aplPredictions[1] then
        context.aplPred = aplPredictions[1]
    end

    if mAIInference then
        local aiCtx = mAIInference:GetContext()
        if aiCtx and aiCtx.inferred then
            context.aiPhase = aiCtx.inferred.combatPhase
            context.aiTip   = aiCtx.inferred.tip
            finalQueue.aiContext = {
                phase           = aiCtx.inferred.combatPhase,
                phaseConfidence = aiCtx.inferred.phaseConfidence,
                targetCount     = aiCtx.targetCount,
                tip             = aiCtx.inferred.tip,
                inferredResource = aiCtx.inferred.resourceState
            }
        end
    end

    if mCooldownOverlay then
        local cds = mCooldownOverlay:GetCooldownStates()
        finalQueue.cooldowns = {}
        local cIdx = 1
        -- GetCooldownStates() returns { [spellID] = {remaining, ready, texture, name, startTime, duration} }
        for spellID, cd in pairs(cds) do
            local isWhitelisted = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
            if isWhitelisted and cd.ready then
                context.cdReadyList[spellID] = true
            end
            if isWhitelisted and not cd.ready then
                cd.spellID = spellID  -- inject spellID for downstream consumers
                finalQueue.cooldowns[cIdx] = cd
                cIdx = cIdx + 1
            end
        end
    end

    if mDefensiveAdvisor then
        local def = mDefensiveAdvisor:GetActiveRecommendation()
        if def then
            context.defSpell  = def.spellID
            context.defUrgency = def.urgency
            finalQueue.defensive = def
        else
            finalQueue.defensive = nil
        end
    end

    -- 2. Build Candidates Map
    local candidates = {}
    if context.blizzSpell then candidates[context.blizzSpell] = true end
    if context.aplPred and context.aplPred.spellID then
        candidates[context.aplPred.spellID] = true
    end
    if context.defSpell then candidates[context.defSpell] = true end
    for sid, _ in pairs(context.cdReadyList) do candidates[sid] = true end

    -- 3. Score & Rank
    local scored = {}
    for sid, _ in pairs(candidates) do
        local score, src = CalculateScore(sid, context, weights)
        if score > 0 then
            table.insert(scored, { spellID = sid, score = score, source = src })
        end
    end
    table.sort(scored, function(a, b) return a.score > b.score end)

    -- 4. Populate Final Queue
    if #scored > 0 then
        local topScore = scored[1].score
        local topConf  = math.min(1.0, topScore / 1.5)

        -- FIX (Bug2): Save the previous main spell ID BEFORE updating,
        -- so GetLastRecommendedSpellID() can return the pre-cast value.
        -- 保存旧主推荐，供 AccuracyTracker 在施法成功后比对。
        lastRecommendedSpellID = finalQueue.main and finalQueue.main.spellID or nil

        finalQueue.main = {
            spellID    = scored[1].spellID,
            source     = scored[1].source,
            confidence = topConf
        }

        -- Fire event if main spell changed
        if prevMainSpellID ~= finalQueue.main.spellID then
            prevMainSpellID = finalQueue.main.spellID
            local eh = RA:GetModule("EventHandler")
            if eh then eh:Fire("ROTAASSIST_QUEUE_UPDATED", finalQueue.main) end
        end

        -- FIX (Bug1): Populate next[] using APL predictions (steps 2+) first,
        -- then fill remaining slots from scored candidates (rank 2+).
        -- 修复：优先用 APL 预测第 2、3步 填充 next[]，再补充 scored 排名第 2+ 的候选。
        for i = 1, #finalQueue.next do finalQueue.next[i] = nil end
        local nIdx = 1

        -- Priority 1: APL prediction steps 2 and beyond
        for i = 2, #aplPredictions do
            if nIdx > 5 then break end
            finalQueue.next[nIdx] = {
                spellID    = aplPredictions[i].spellID,
                confidence = aplPredictions[i].confidence or 0.7
            }
            nIdx = nIdx + 1
        end

        -- Priority 2: scored candidates rank 2+ (deduplicate against APL predictions)
        for i = 2, math.min(#scored, 6) do
            if nIdx > 5 then break end
            local dominated = false
            for _, existing in ipairs(finalQueue.next) do
                if existing and existing.spellID == scored[i].spellID then
                    dominated = true
                    break
                end
            end
            if not dominated then
                finalQueue.next[nIdx] = {
                    spellID    = scored[i].spellID,
                    confidence = math.min(1.0, scored[i].score / 1.5)
                }
                nIdx = nIdx + 1
            end
        end
    else
        -- FIX (Bug2): Also reset lastRecommendedSpellID when queue clears
        lastRecommendedSpellID = finalQueue.main and finalQueue.main.spellID or nil
        finalQueue.main = nil
        for i = 1, #finalQueue.next do finalQueue.next[i] = nil end
        if prevMainSpellID ~= nil then
            prevMainSpellID = nil
            local eh = RA:GetModule("EventHandler")
            if eh then eh:Fire("ROTAASSIST_QUEUE_UPDATED", nil) end
        end
    end
end

local function onUpdate(_, elapsed_dt)
    lastUpdate = lastUpdate + elapsed_dt
    if lastUpdate >= THROTTLE_UPDATE then
        lastUpdate = 0
        AssembleQueue()
    end
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get the finalized, prioritized prediction queue.
---获取最终优先排序的预测队列。
---@return table
function SmartQueueManager:GetFinalQueue()
    return finalQueue
end

---Get the main spell ID that was recommended in the *previous* frame.
---Returns nil if there was no prior recommendation or the queue was empty.
---获取上一帧的主推荐技能 ID，用于施法成功后比对准确度。
---@return number|nil spellID
function SmartQueueManager:GetLastRecommendedSpellID()
    return lastRecommendedSpellID
end

---Backward compatible wrapper for existing UI modules expecting RecommendationManager:GetDisplayData()
---为期望从 RecommendationManager 拿到类似格式数据的旧 UI 模块提供兼容。
---@return table
function SmartQueueManager:GetDisplayData()
    local data = {
        main        = nil,
        predictions = {},
        cooldowns   = finalQueue.cooldowns,
        defensive   = finalQueue.defensive,
        aiContext   = finalQueue.aiContext
    }

    if finalQueue.main then
        data.main = {
            spellID    = finalQueue.main.spellID,
            confidence = finalQueue.main.confidence,
            source     = finalQueue.main.source
        }
    end

    for i, nxt in ipairs(finalQueue.next) do
        data.predictions[i] = {
            spellID    = nxt.spellID,
            confidence = nxt.confidence
        }
    end

    return data
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function SmartQueueManager:OnInitialize()
    updateFrame = CreateFrame("Frame")
    updateFrame:Hide()
end

function SmartQueueManager:OnEnable()
    mBridge           = RA:GetModule("AssistedCombatBridge")
    mAIInference      = RA:GetModule("AIInference")
    mAPLEngine        = RA:GetModule("APLEngine")
    mCooldownOverlay  = RA:GetModule("CooldownOverlay")
    mDefensiveAdvisor = RA:GetModule("DefensiveAdvisor")

    updateFrame:SetScript("OnUpdate", onUpdate)
    updateFrame:Show()
end

function SmartQueueManager:OnDisable()
    if updateFrame then
        updateFrame:SetScript("OnUpdate", nil)
        updateFrame:Hide()
    end
    prevMainSpellID        = nil
    lastRecommendedSpellID = nil
    for i = 1, #finalQueue.next do finalQueue.next[i] = nil end
    finalQueue.main = nil
end
