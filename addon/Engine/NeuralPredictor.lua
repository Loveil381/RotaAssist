------------------------------------------------------------------------
-- RotaAssist - Neural Predictor (v2)
-- 神经预测器 / Neural Predictor
-- Pure-Lua prediction engine combining:
--   1. Pre-computed decision trees from Data/DecisionTrees/*.lua
--   2. Default Markov matrices from Data/TransitionMatrix/*.lua
--   3. Player's personal Markov matrix from SavedVariables
-- 事前構築された決定木 + デフォルトマルコフ行列 + 個人マルコフ行列
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local NeuralPredictor = {}
RA:RegisterModule("NeuralPredictor", NeuralPredictor)

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local WEIGHT_DT         = 0.6   -- 决策树权重 / decision tree weight
local WEIGHT_MK         = 0.4   -- 马尔可夫权重 / Markov weight
local BLIZZ_BONUS       = 1.0   -- 暴雪推荐加分 / Blizzard rec bonus
local NORM_INTERVAL     = 30    -- 归一化間隔(秒) / normalization interval
local TOP_K             = 3     -- 马尔可夫返回候选数 / Markov top-K
local PERSONAL_BLEND    = 0.40  -- 个人矩阵混合比例 / personal matrix blend ratio
local DEFAULT_BLEND     = 0.60  -- 默认矩阵混合比例 / default matrix blend ratio
local PERSONAL_MIN_TRANS = 100  -- 个人矩阵混合最小转移数 / min transitions for blending

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

--- 当前专精的决策树 / DT cache for current spec
local activeDT = nil

--- 当前专精的默认转移矩阵 / default TM for current spec
local activeTM = nil

--- 个人马尔可夫计数矩阵 / personal Markov count matrix
local personalCounts = {}

--- 个人马尔可夫概率矩阵 / personal normalized probabilities
local personalProbs = {}

--- 混合概率矩阵 / blended Markov probability matrix
local blendedProbs = {}

--- 脏标记 / dirty flag for normalization
local dirtyMatrix = false

--- 上次归一化时刻 / last normalization timestamp
local lastNormTime = 0

--- 总个人转移计数 / total personal transitions
local personalTransitionCount = 0

--- 可复用特征表 / reusable feature table (zero-alloc)
local featureReuse = {
    lastSpellID = 0,
    secondLastSpellID = 0,
    thirdLastSpellID = 0,
    timeSinceLastCast = 0,
    nameplateCount = 1,
    secondaryResource = 0,
    secondaryResourceMax = 1,
    blizzardRecommendation = 0,
    combatDuration = 0,
    specID = 0,
}

--- 零分配复用表 / wipe & reuse tables
local reuseTemp = {}
local reuseCandidates = {}
local reuseSources = {}
local reuseSorted = {}

------------------------------------------------------------------------
-- Normalization & Blending
------------------------------------------------------------------------

---Normalize personal count matrix to probabilities.
---将个人计数矩阵归一化为概率矩阵。
local function NormalizePersonalMatrix()
    personalProbs = {}
    for fromID, row in pairs(personalCounts) do
        local total = 0
        for _, cnt in pairs(row) do total = total + cnt end
        if total > 0 then
            personalProbs[fromID] = {}
            for toID, cnt in pairs(row) do
                personalProbs[fromID][toID] = cnt / total
            end
        end
    end
end

---Blend personal and default TM into blendedProbs.
---将个人矩阵与默认矩阵混合。
local function BlendMatrices()
    blendedProbs = {}

    -- Gather all fromIDs from both sources
    local allFromIDs = {}
    if activeTM and activeTM.matrix then
        for fid, _ in pairs(activeTM.matrix) do allFromIDs[fid] = true end
    end
    for fid, _ in pairs(personalProbs) do allFromIDs[fid] = true end

    local usePersonal = personalTransitionCount >= PERSONAL_MIN_TRANS

    for fid, _ in pairs(allFromIDs) do
        blendedProbs[fid] = {}
        local allToIDs = {}

        local defaultRow = activeTM and activeTM.matrix and activeTM.matrix[fid] or {}
        local personalRow = personalProbs[fid] or {}

        for tid, _ in pairs(defaultRow) do allToIDs[tid] = true end
        if usePersonal then
            for tid, _ in pairs(personalRow) do allToIDs[tid] = true end
        end

        for tid, _ in pairs(allToIDs) do
            local dProb = defaultRow[tid] or 0
            local pProb = personalRow[tid] or 0
            if usePersonal then
                blendedProbs[fid][tid] = DEFAULT_BLEND * dProb + PERSONAL_BLEND * pProb
            else
                blendedProbs[fid][tid] = dProb
            end
        end
    end

    lastNormTime = GetTime()
    dirtyMatrix = false
end

------------------------------------------------------------------------
-- Decision Tree
------------------------------------------------------------------------

---Predict using the loaded decision tree.
---使用加载的决策树进行预测。
---@param features table
---@return table|nil {spellID, confidence}
function NeuralPredictor:PredictFromDecisionTree(features)
    if not activeDT or not activeDT.Evaluate then return nil end
    local ok, result = pcall(activeDT.Evaluate, features)
    if ok and result then return result end
    return nil
end

------------------------------------------------------------------------
-- Markov Chain
------------------------------------------------------------------------

---Predict next spells using blended Markov matrix.
---使用混合马尔可夫矩阵预测下一个技能。
---@param lastSpellID number
---@param topN number|nil
---@return table[] {{spellID, probability}, ...}
function NeuralPredictor:PredictFromMarkov(lastSpellID, topN)
    topN = topN or TOP_K
    local result = {}

    -- Ensure matrix is fresh
    if dirtyMatrix or (GetTime() - lastNormTime > NORM_INTERVAL) then
        NormalizePersonalMatrix()
        BlendMatrices()
    end

    local row = blendedProbs[lastSpellID]
    if not row then
        -- Fallback: try default TM directly
        if activeTM and activeTM.GetTopTransitions then
            return activeTM.GetTopTransitions(lastSpellID, topN)
        end
        return result
    end

    wipe(reuseTemp)
    for sid, prob in pairs(row) do
        reuseTemp[#reuseTemp + 1] = { spellID = sid, probability = prob }
    end
    table.sort(reuseTemp, function(a, b) return a.probability > b.probability end)

    for i = 1, math.min(topN, #reuseTemp) do
        result[i] = reuseTemp[i]
    end
    return result
end

---Update personal Markov count matrix on each player cast.
---在每次玩家施法时更新个人马尔可夫计数矩阵。
---@param fromSpellID number
---@param toSpellID number
function NeuralPredictor:UpdateMarkovMatrix(fromSpellID, toSpellID)
    if not fromSpellID or fromSpellID == 0 or not toSpellID or toSpellID == 0 then return end
    if toSpellID == 6603 or RA:IsSpellPassive(toSpellID) then return end
    if not personalCounts[fromSpellID] then
        personalCounts[fromSpellID] = {}
    end
    personalCounts[fromSpellID][toSpellID] = (personalCounts[fromSpellID][toSpellID] or 0) + 1
    personalTransitionCount = personalTransitionCount + 1
    dirtyMatrix = true
end

------------------------------------------------------------------------
-- Feature Building
------------------------------------------------------------------------

---Assemble feature vector from all available modules.
---从所有可用模块收集特征向量 (零分配)。
---@return table features
function NeuralPredictor:BuildFeatures()
    local f = featureReuse

    -- Cast history
    local recorder = RA:GetModule("CastHistoryRecorder")
    if recorder then
        f.lastSpellID       = recorder:GetNthLastSpellID(1) or 0
        f.secondLastSpellID = recorder:GetNthLastSpellID(2) or 0
        f.thirdLastSpellID  = recorder:GetNthLastSpellID(3) or 0
        local lastCasts = recorder:GetRecentCasts(1)
        if lastCasts and lastCasts[1] then
            f.timeSinceLastCast = GetTime() - (lastCasts[1].timestamp or GetTime())
        else
            f.timeSinceLastCast = 0
        end
    end

    -- Nameplate count + combat duration
    local patDet = RA:GetModule("PatternDetector")
    if patDet then
        local npOk, npCount = pcall(patDet.GetNameplateCount, patDet)
        f.nameplateCount = (npOk and npCount) or 1

        local phaseOk, phase = pcall(patDet.GetPhase, patDet)
        if phaseOk and phase and phase.signals then
            f.combatDuration = phase.signals.combatDur or 0
        end
    end

    -- Blizzard recommendation
    local bridge = RA:GetModule("AssistedCombatBridge")
    if bridge then
        local rec = bridge:GetCurrentRecommendation()
        f.blizzardRecommendation = rec and rec.spellID or 0
    end

    -- WOW 12.0 SECRET VALUE SAFE: Secondary resource (should be non-secret, but guarded)
    local specDetector = RA:GetModule("SpecDetector")
    if specDetector then
        local spec = specDetector:GetCurrentSpec()
        f.specID = spec and spec.specID or 0
        if spec and RA.SpecEnhancements and RA.SpecEnhancements[f.specID] then
            local enh = RA.SpecEnhancements[f.specID]
            if enh.secondaryPowerType then
                local ok1, cur = pcall(UnitPower, "player", enh.secondaryPowerType)
                local ok2, mx  = pcall(UnitPowerMax, "player", enh.secondaryPowerType)
                cur = (ok1 and cur) or 0
                mx  = (ok2 and mx and mx > 0 and mx) or 1
                -- WOW 12.0 SECRET VALUE SAFE: guard against unexpected secret values
                if issecretvalue and (issecretvalue(cur) or issecretvalue(mx)) then
                    cur, mx = 0, 1
                end
                f.secondaryResource = cur
                f.secondaryResourceMax = mx
            end
        end
    end

    return f
end

------------------------------------------------------------------------
-- Combined Prediction
------------------------------------------------------------------------

---Get combined prediction blending DT, Markov, and Blizzard.
---混合决策树、马尔可夫和暴雪推荐获取组合预测。
---@return table {primary={spellID,confidence,source}, alternatives={{spellID,confidence,source},...}}
function NeuralPredictor:GetCombinedPrediction()
    local features = self:BuildFeatures()

    local dtResult = self:PredictFromDecisionTree(features)
    local mkResults = self:PredictFromMarkov(features.lastSpellID, TOP_K)
    local blizzSpell = features.blizzardRecommendation

    -- 候选评分表 / candidate score map
    wipe(reuseCandidates)
    wipe(reuseSources)
    local function AddCandidate(spellID, score, source)
        if not spellID or spellID == 0 then return end
        if spellID == 6603 then return end  -- auto-attack

        -- 1. 被动技能过滤（API + 黑名单）
        -- Filter passive spells (API + hardcoded blacklist)
        if RA:IsSpellPassive(spellID) then return end
        local SQM_BLACKLIST = {
            [203555] = true,  -- Demon Blades
            [290271] = true,  -- Demon Blades AI
            [412713] = true,  -- Interwoven Threads / 丝缕交织
        }
        if SQM_BLACKLIST[spellID] then return end

        -- 2. 未学习技能过滤：玩家未点的天赋不推荐
        -- Filter unlearned spells: skip talents the player hasn't selected
        if IsPlayerSpell then
            local okK, isK = pcall(IsPlayerSpell, spellID)
            if okK and not isK then return end
        end

        -- 3. 不可施放检查：覆盖 IsSpellPassive 漏判的"增强型被动"技能（如思缕交织）
        -- Usability check: catches "enhanced passive" spells that IsSpellPassive misses
        if C_Spell and C_Spell.IsSpellUsable then
            local okU, usable = pcall(C_Spell.IsSpellUsable, spellID)
            if okU and usable == false then return end
        end

        -- 4. CD 过滤：正在冷却中（>1.5秒）的技能不进入候选
        -- Cooldown filter: skip spells with >1.5s remaining cooldown
        local remaining = RA:GetSpellCooldownSafe(spellID)
        if remaining and remaining > 1.5 then return end

        reuseCandidates[spellID] = (reuseCandidates[spellID] or 0) + score
        if not reuseSources[spellID] or score > (reuseSources[spellID].score or 0) then
            reuseSources[spellID] = { source = source, score = score }
        end
    end

    -- Blizzard recommendation (strongest signal)
    if blizzSpell and blizzSpell ~= 0 then
        AddCandidate(blizzSpell, BLIZZ_BONUS, "BLIZZARD")
    end

    -- Decision tree contribution
    if dtResult and dtResult.spellID then
        AddCandidate(dtResult.spellID, dtResult.confidence * WEIGHT_DT, "DT")
    end

    -- Markov contribution (weighted by rank)
    local mkWeights = { 0.4, 0.2, 0.1 }
    for i, mk in ipairs(mkResults) do
        local w = mkWeights[i] or 0.05
        AddCandidate(mk.spellID, mk.probability * w, "MARKOV")
    end

    -- Sort candidates
    wipe(reuseSorted)
    for sid, score in pairs(reuseCandidates) do
        reuseSorted[#reuseSorted + 1] = {
            spellID = sid,
            confidence = math.min(1.0, score),
            source = reuseSources[sid] and reuseSources[sid].source or "UNKNOWN"
        }
    end
    table.sort(reuseSorted, function(a, b) return a.confidence > b.confidence end)

    local primary = reuseSorted[1] or { spellID = blizzSpell or 0, confidence = 0.3, source = "BLIZZARD" }
    local alts = {}
    for i = 2, math.min(#reuseSorted, 4) do
        alts[#alts + 1] = reuseSorted[i]
    end

    return {
        primary = primary,
        alternatives = alts
    }
end

------------------------------------------------------------------------
-- Spec Change & Persistence
------------------------------------------------------------------------

---Load DT and TM for a given specID.
---为指定专精加载决策树和转移矩阵。
---@param specID number
function NeuralPredictor:OnSpecChanged(specID)
    -- Load decision tree
    if RA.DecisionTrees and RA.DecisionTrees[specID] then
        activeDT = RA.DecisionTrees[specID]
    else
        activeDT = nil
    end

    -- Load default transition matrix
    if RA.TransitionMatrices and RA.TransitionMatrices[specID] then
        activeTM = RA.TransitionMatrices[specID]
    else
        activeTM = nil
    end

    -- Force re-blend
    dirtyMatrix = true
    lastNormTime = 0
end

---Save personal Markov matrix to SavedVariables.
---将个人马尔可夫矩阵保存到 SavedVariables。
function NeuralPredictor:SavePersonalMatrix()
    if not RA.db then return end
    RA.db.char = RA.db.char or {}
    RA.db.char.markovMatrix = personalCounts
    RA.db.char.markovTransitionCount = personalTransitionCount
end

---Load personal Markov matrix from SavedVariables.
---从 SavedVariables 加载个人马尔可夫矩阵。
function NeuralPredictor:LoadPersonalMatrix()
    if not RA.db then return end
    RA.db.char = RA.db.char or {}
    if RA.db.char.markovMatrix and type(RA.db.char.markovMatrix) == "table" then
        personalCounts = RA.db.char.markovMatrix
        personalTransitionCount = RA.db.char.markovTransitionCount or 0
        NormalizePersonalMatrix()
    end
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function NeuralPredictor:OnInitialize()
    RA.DecisionTrees = RA.DecisionTrees or {}
    RA.TransitionMatrices = RA.TransitionMatrices or {}
end

function NeuralPredictor:OnEnable()
    self:LoadPersonalMatrix()

    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ROTAASSIST_SPEC_CHANGED", "NeuralPredictor", function()
            local sd = RA:GetModule("SpecDetector")
            if sd then
                local spec = sd:GetCurrentSpec()
                if spec then
                    self:OnSpecChanged(spec.specID)
                end
            end
        end)

        eh:Subscribe("PLAYER_LOGOUT", "NeuralPredictor", function()
            self:SavePersonalMatrix()
        end)
    end

    -- Initial load for current spec
    local sd = RA:GetModule("SpecDetector")
    if sd then
        local spec = sd:GetCurrentSpec()
        if spec then
            self:OnSpecChanged(spec.specID)
        end
    end
end

function NeuralPredictor:OnDisable()
    self:SavePersonalMatrix()
end
