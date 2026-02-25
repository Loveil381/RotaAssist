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
local lastUpdate = 0

-- Engine Module References (cached for speed)
local mBridge
local mAIInference
local mAPLEngine
local mCooldownOverlay
local mDefensiveAdvisor

-- Outputs (zero-allocation recycle)
local finalQueue = {
    main = nil,
    next = {},
    cooldowns = {},
    defensive = nil,
    phase = "UNKNOWN",
    tip = nil,
    accuracy = 0,
    aiContext = nil -- Keep backward compatible with UI that reads aiContext
}

-- Previous main spell ID to fire event on change
local prevMainSpellID = nil

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

    -- 2. APL Engine Prediction
    if context.aplPred and context.aplPred.spellID == spellID then
        score = score + (context.aplPred.confidence * weights.aplWeight)
        if score > (1.0 * weights.blizzardWeight) then
            primarySource = "APL"
        end
    end

    -- 3. AI Inference Tip Bonus (e.g. suggests pooling or AoE spell)
    if context.aiTip and context.aiTip.text then
        -- We don't have a direct spellID map from tips, but we give a generic bump if they match a meta state
        -- Simplified logic: no direct DB link, let APL/Blizzard drive mostly.
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
        finalQueue.main = nil
        finalQueue.next = {}
        finalQueue.cooldowns = {}
        finalQueue.defensive = nil
        return
    end

    local weights = RA.db and RA.db.profile.smartQueue or defaultWeights

    -- 1. Gather Context
    local context = {
        blizzSpell = nil,
        aplPred = nil,
        cdReadyList = {},
        defSpell = nil,
        defUrgency = 0,
        aiPhase = "NORMAL",
        aiTip = nil
    }

    if mBridge then
        local rec = mBridge:GetCurrentRecommendation()
        context.blizzSpell = rec and rec.spellID or nil
    end

    if mAPLEngine then
        context.aplPred = mAPLEngine:PredictNext(nil, nil)
    end

    if mAIInference then
        local aiCtx = mAIInference:GetContext()
        if aiCtx and aiCtx.inferred then
            context.aiPhase = aiCtx.inferred.combatPhase
            context.aiTip = aiCtx.inferred.tip
            finalQueue.aiContext = {
                phase = aiCtx.inferred.combatPhase,
                phaseConfidence = aiCtx.inferred.phaseConfidence,
                targetCount = aiCtx.targetCount,
                tip = aiCtx.inferred.tip,
                inferredResource = aiCtx.inferred.resourceState
            }
        end
    end

    if mCooldownOverlay then
        local cds = mCooldownOverlay:GetCooldownStates()
        finalQueue.cooldowns = {}
        local cIdx = 1
        for _, cd in ipairs(cds) do
            if cd.isWhitelisted and cd.ready then
                context.cdReadyList[cd.spellID] = true
            end
            if cd.isWhitelisted and not cd.ready then
                finalQueue.cooldowns[cIdx] = cd
                cIdx = cIdx + 1
            end
        end
    end

    if mDefensiveAdvisor then
        local def = mDefensiveAdvisor:GetActiveRecommendation()
        if def then
            context.defSpell = def.spellID
            context.defUrgency = def.urgency
            finalQueue.defensive = def
        else
            finalQueue.defensive = nil
        end
    end

    -- 2. Build Candidates Map
    local candidates = {}
    if context.blizzSpell then candidates[context.blizzSpell] = true end
    if context.aplPred and context.aplPred.spellID then candidates[context.aplPred.spellID] = true end
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
        -- Normalize top score for confidence (max 1.0)
        local topScore = scored[1].score
        local topConf = math.min(1.0, topScore / 1.5) -- arbitrarily normalize against 1.5 max expected
        
        finalQueue.main = {
            spellID = scored[1].spellID,
            source = scored[1].source,
            confidence = topConf
        }
        
        -- Fire event if main spell changed
        if prevMainSpellID ~= finalQueue.main.spellID then
            prevMainSpellID = finalQueue.main.spellID
            local eh = RA:GetModule("EventHandler")
            if eh then eh:Fire("ROTAASSIST_QUEUE_UPDATED", finalQueue.main) end
        end

        -- Populate next queue
        for i = 1, #finalQueue.next do finalQueue.next[i] = nil end -- clear
        local nIdx = 1
        for i = 2, math.min(#scored, 6) do
            local conf = math.min(1.0, scored[i].score / 1.5)
            finalQueue.next[nIdx] = { spellID = scored[i].spellID, confidence = conf }
            nIdx = nIdx + 1
        end
    else
        finalQueue.main = nil
        for i = 1, #finalQueue.next do finalQueue.next[i] = nil end
        if prevMainSpellID ~= nil then
            prevMainSpellID = nil
            local eh = RA:GetModule("EventHandler")
            if eh then eh:Fire("ROTAASSIST_QUEUE_UPDATED", nil) end
        end
    end
end

local function onUpdate(_, elapsed)
    lastUpdate = lastUpdate + elapsed
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

---Backward compatible wrapper for existing UI modules expecting RecommendationManager:GetDisplayData()
---为期望从 RecommendationManager 拿到类似格式数据的旧 UI 模块提供兼容。
---@return table
function SmartQueueManager:GetDisplayData()
    local data = {
        main = nil,
        predictions = {},
        cooldowns = finalQueue.cooldowns,
        defensive = finalQueue.defensive,
        aiContext = finalQueue.aiContext
    }

    if finalQueue.main then
        data.main = {
            spellID = finalQueue.main.spellID,
            confidence = finalQueue.main.confidence,
            source = finalQueue.main.source
        }
    end

    for i, nxt in ipairs(finalQueue.next) do
        data.predictions[i] = {
            spellID = nxt.spellID,
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
    mBridge = RA:GetModule("AssistedCombatBridge")
    mAIInference = RA:GetModule("AIInference")
    mAPLEngine = RA:GetModule("APLEngine")
    mCooldownOverlay = RA:GetModule("CooldownOverlay")
    mDefensiveAdvisor = RA:GetModule("DefensiveAdvisor")

    updateFrame:SetScript("OnUpdate", onUpdate)
    updateFrame:Show()
end

function SmartQueueManager:OnDisable()
    if updateFrame then
        updateFrame:SetScript("OnUpdate", nil)
        updateFrame:Hide()
    end
    prevMainSpellID = nil
    for i = 1, #finalQueue.next do finalQueue.next[i] = nil end
    finalQueue.main = nil
end
