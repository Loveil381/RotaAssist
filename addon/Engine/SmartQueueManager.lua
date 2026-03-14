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

-- 已知的被动/不可施放技能黑名单（API 查询的快速路径备份）
-- Known passive/non-castable spell blacklist (fast-path backup for API queries)
local PASSIVE_BLACKLIST = RA.Registry.PASSIVE_BLACKLIST

-- 抗抖动配置 / Anti-flicker config
local FLICKER_THRESHOLD = 2
local previousNextSpells = {} -- [index] = spellID
local flickerCounters   = {}  -- [index] = count
-- Engine Module References (cached for speed)
local mBridge
local mAIInference
local mAPLEngine
local mCooldownOverlay
local mDefensiveAdvisor
local mNeuralPredictor

--- Check if a spell is currently on significant cooldown (> 1.0s remaining).
--- 检查技能是否在有效 CD 中（超过 1.0秒），用于过滤 next[] 中的预测。
--- FIX (OverridePair): Also checks the paired override ID (e.g. Death Sweep for Blade Dance).
--- 同时检查覆盖对技能的 CD 状态（如 Blade Dance ↔ Death Sweep）。
local function IsSpellOnCooldown(spellID)
    if not spellID then return false end
    -- Primary: check CooldownOverlay tracked states
    if mCooldownOverlay then
        local cds = mCooldownOverlay:GetCooldownStates()
        local cdState = cds[spellID]
        if cdState then
            if not cdState.ready and cdState.remaining and cdState.remaining > 1.0 then
                return true
            end
            -- FIX (OverridePair): paired ID check when primary reports ready
            -- 覆盖对检查：主 ID 就绪时查看配对 ID 是否在 CD
            local pairedID = RA.KNOWN_OVERRIDE_PAIRS and RA.KNOWN_OVERRIDE_PAIRS[spellID]
            if pairedID then
                local pairedState = cds[pairedID]
                if pairedState and not pairedState.ready
                   and pairedState.remaining and pairedState.remaining > 1.0 then
                    return true
                end
            end
            return false
        end
    end
    -- Fallback: direct API query for spells not tracked by CooldownOverlay
    local remaining = RA:GetSpellCooldownSafe(spellID)
    if remaining and remaining > 1.0 then
        return true
    end

    -- FIX (OverridePair): check paired ID via direct API when primary is not on CD
    -- 覆盖对 API 回退：主 ID 未在 CD 时检查配对 ID
    if remaining ~= nil then
        local pairedID = RA.KNOWN_OVERRIDE_PAIRS and RA.KNOWN_OVERRIDE_PAIRS[spellID]
        if pairedID then
            local pRemaining = RA:GetSpellCooldownSafe(pairedID)
            if pRemaining and pRemaining > 1.0 then
                return true
            end
        end
    end

    -- remaining == nil (secret value): estimate from cast history
    -- 12.0 secret value 回退：从施法历史记录中估算冷却状态
    if remaining == nil then
        local wsInfo = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
        if wsInfo and wsInfo.cdSeconds and wsInfo.cdSeconds > 1.5 then
            local recorder = RA:GetModule("CastHistoryRecorder")
            if recorder then
                local recent = recorder:GetRecentCasts(20)
                for _, cast in ipairs(recent) do
                    if cast.spellID == spellID then
                        local elapsedTime = GetTime() - cast.timestamp
                        if elapsedTime < wsInfo.cdSeconds then
                            return true
                        end
                        break
                    end
                end
            end
        end
    end
    return false
end

SmartQueueManager._IsSpellOnCooldown = IsSpellOnCooldown

--- Unified castability gate: checks passive, unlearned, unusable, and cooldown.
--- 统一可施放性检查：被动、未学习、不可施放、冷却中四重过滤。
--- @param spellID number
--- @return boolean castable
local function IsSpellCastable(spellID)
    if not spellID or spellID == 0 then return false end
    -- 1. 被动黑名单快速路径
    if PASSIVE_BLACKLIST[spellID] then return false end
    -- 2. RA 被动检测
    if RA.IsSpellPassive and RA:IsSpellPassive(spellID) then return false end
    -- 3. 未学习检测
    if IsPlayerSpell then
        local okL, known = pcall(IsPlayerSpell, spellID)
        if okL and not known then return false end
    end
    -- 4. 不可施放检测（覆盖 Hero Talent 增强型被动等 IsSpellPassive 漏判的情况）
    if C_Spell and C_Spell.IsSpellUsable then
        local okU, usable = pcall(C_Spell.IsSpellUsable, spellID)
        if okU and usable == false then return false end
    end
    -- 5. 冷却中（>1.0秒）
    if IsSpellOnCooldown(spellID) then return false end
    return true
end

SmartQueueManager._IsSpellCastable = IsSpellCastable

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

local updateFrame = nil
local lastUpdate  = 0

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

-- 上一帧主推荐ID，供 AccuracyTracker 做上一帧比对。
local lastRecommendedSpellID = nil

-- Sticky Blizzard recommendation (caches last known ID if Blizzard temporarily returns nil)
-- 记忆 Blizzard 推荐（防止 GCD 或延迟导致推荐瞬间消失引起预测抖动）
local lastKnownBlizzSpell = nil

-- 施法后的软屏蔽：在真实 CD 数据到来前临时阻止刚施放的技能被推荐
-- Soft-block: temporarily suppress the just-cast spell until SPELL_UPDATE_COOLDOWN confirms the real CD.
local softBlockedSpells = {}
local SOFT_BLOCK_DURATION = 0.6  -- seconds until soft-block auto-expires

-- 引导技能：施法成功后不清除 lastKnownBlizzSpell，保持引导结束后下一步推荐稳定
-- Channeled spells: don't clear sticky on success — keep showing next-spell during channel.
local CHANNELED_SPELL_IDS = {
    [198013] = true,  -- Eye Beam (Havoc)
    [212084] = true,  -- Fel Devastation (Vengeance)
    [258920] = true,  -- Immolation Aura (channel phase)
}

-- 引导期间捕获的「引导结束后下一步」spellID，用于 sticky fallback
-- Captured next-spell spellID during a channel, used as sticky fallback.
local channelNextSpell = nil

local context_reuse = { blizzSpell=nil, aplPred=nil, cdReadyList={}, blindSpotCandidates={}, defSpell=nil, defUrgency=0, aiPhase="NORMAL", aiTip=nil }
local candidates_reuse = {}
local scored_reuse = {}
local toRemove_reuse = {}
local passiveRemove_reuse = {}
local sbRemove_reuse = {}
local unlearnedRemove_reuse = {}
-- 最近一帧的 APL 预测结果（模块级，供 CHANNEL_START 闭包读取）
-- Most-recent APL predictions at module level so the CHANNEL_START closure can read them.
local aplPredictions = {}

------------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------------

---Calculate priority score for a spell candidate.
---计算候选技能的优先级得分。
---@param spellID number
---@param context table
---@param weights table
---@param aplPredictions table  Full APL prediction array for tiered scoring
---@return number score, string source
local function CalculateScore(spellID, context, weights, aplPredictions)
    local score = 0
    local primarySource = "UNKNOWN"

    -- 1. Blizzard Recommendation
    if context.blizzSpell == spellID then
        score = score + (1.0 * weights.blizzardWeight)
        primarySource = "BLIZZARD"
    end

    -- 2. APL Engine Tiered Prediction Scoring
    -- Step-1 gets full APL weight, step-2 gets 0.5×, step-3 gets 0.3×.
    -- Skip if already scored as a blind-spot to avoid double-counting.
    -- APL 分层评分：第1步全权重，第2步0.5×，第3步0.3×；盲区技能跳过避免双重计分
    if aplPredictions and not (context.blindSpotCandidates and context.blindSpotCandidates[spellID]) then
        local APL_TIER = { 1.0, 0.5, 0.3 }
        for i, pred in ipairs(aplPredictions) do
            if pred.spellID == spellID then
                local tier = APL_TIER[i] or 0
                score = score + (pred.confidence * weights.aplWeight * tier)
                if score > (1.0 * weights.blizzardWeight) then
                    primarySource = "APL"
                end
                break  -- a spell only appears once in aplPredictions
            end
        end
    end

    -- 3. Blind-spot bonus: APL-prioritised CD that Blizzard's rotation omits.
    -- 盲区加分：APL 优先级较高且 Blizzard 循环中缺少的就绪 CD，得分 >= 1.0 超越 Blizzard
    if context.blindSpotCandidates and context.blindSpotCandidates[spellID] then
        score = score + 1.2  -- 必须超过 Blizzard 的 1.0，使盲区技能可以成为主推荐
        primarySource = "APL_BLINDSPOT"
    end

    -- 4. AI Inference Tip Bonus
    if context.aiTip and context.aiTip.text then
        -- Simplified: let APL/Blizzard drive mostly.
    end

    -- 5. Cooldown Overlay (whitelisted CDs ready during BURST prep)
    if context.cdReadyList[spellID] and context.aiPhase == "BURST_PREPARE" then
        score = score + (0.5 * weights.cdWeight)
    end

    -- 6. Defensive Urgency
    if context.defSpell == spellID then
        score = score + ((context.defUrgency or 1.0) * weights.defWeight)
        primarySource = "DEFENSIVE"
    end

    return score, primarySource
end

-- Expose for unit testing (module-level reference)
SmartQueueManager._CalculateScore = CalculateScore

------------------------------------------------------------------------
-- Update Loop
------------------------------------------------------------------------

local function AssembleQueue()
    if not InCombatLockdown() and not (RA.db and RA.db.profile.display.showOutOfCombat) then
        finalQueue.main      = nil
        finalQueue.next      = {}
        finalQueue.cooldowns = {}
        finalQueue.defensive = nil
        lastKnownBlizzSpell  = nil -- Clear cache out of combat
        wipe(previousNextSpells)   -- 清空抗抖动缓存
        wipe(flickerCounters)
        return
    end

    local weights = RA.db and RA.db.profile.smartQueue or defaultWeights

    -- 1. Gather Context
    local context = context_reuse
    context.blizzSpell = nil
    context.aplPred = nil
    wipe(context.cdReadyList)
    wipe(context.blindSpotCandidates)
    context.defSpell = nil
    context.defUrgency = 0
    context.aiPhase = "NORMAL"
    context.aiTip = nil

    if mBridge then
        local rec = mBridge:GetCurrentRecommendation()
        context.blizzSpell = rec and rec.spellID or nil

        -- Sticky fallback priority:
        -- 1. Real Blizzard recommendation (always wins)
        -- 2. channelNextSpell  — captured at channel start (引导中：显示引导后的下一个技能)
        -- 3. lastKnownBlizzSpell — normal inter-GCD sticky
        if context.blizzSpell then
            lastKnownBlizzSpell = context.blizzSpell
        elseif channelNextSpell then
            context.blizzSpell = channelNextSpell
        elseif lastKnownBlizzSpell then
            -- FIX (Round14-Bug1): sticky fallback 必须验证技能是否仍然可施放
            -- Sticky fallback must verify the spell is not on cooldown before reuse
            if not IsSpellOnCooldown(lastKnownBlizzSpell) then
                context.blizzSpell = lastKnownBlizzSpell
            else
                -- 技能已进 CD，清除 sticky，让队列自然降级到 APL/AI 推荐
                lastKnownBlizzSpell = nil
            end
        end
    end

    -- Build Blizzard rotation spell set for blind-spot detection
    -- Blizzard 循环技能集合，用于检测盲区技能
    local rotationSpells = {}
    if mBridge then
        local list = mBridge:GetRotationSpells()
        for _, sid in ipairs(list) do
            rotationSpells[sid] = true
        end
    end

    -- FIX (Bug1): PredictNext returns an ARRAY of predictions.
    -- Parse it correctly; the first element joins scoring, rest go to next[].
    -- 修复：PredictNext 返回数组，第一个元素参与评分，其余填充 next[]。
    -- Reset APL predictions array (module-level, reused across frames)
    -- 重置 APL 预测数组（模块级，跨帧复用）
    local currentTargetCount = 1
    if mAIInference then
        local aiCtx = mAIInference:GetContext()
        if aiCtx and aiCtx.targetCount then
            currentTargetCount = aiCtx.targetCount
        end
    end
    wipe(aplPredictions)  -- reset module-level table each frame
    if mAPLEngine and mAPLEngine.HasAPL and mAPLEngine:HasAPL() then
        -- FIX (P0-Bug2): Build a valid limitedState table from context
        local limitedState = {
            resource        = 0,
            cooldowns       = {},
            inMeta          = false,
            targetCount     = 1,
            combatDuration  = 0,   -- 传递战斗时长给 APLEngine 用于 opener 检测
            softBlocked     = softBlockedSpells,  -- 传递软屏蔽表给 APLEngine / pass soft-block map
        }

        -- Read the normalized SpecEnhancements resource config.
        -- 读取统一后的 SpecEnhancements 资源配置。
        local powerType = 0  -- default to mana
        local specDetector = RA:GetModule("SpecDetector")
        if specDetector then
            local spec = specDetector:GetCurrentSpec()
            if spec and RA.SpecEnhancements and RA.SpecEnhancements[spec.specID] then
                local resConfig = RA.SpecEnhancements[spec.specID].resource
                if resConfig then
                    powerType = resConfig.powerType or 0
                end
            end
        end
        local rawPower = UnitPower("player", powerType)
        if rawPower and not issecretvalue(rawPower) then
            limitedState.resource = rawPower
        else
            limitedState.resource = 0
        end

        -- Populate cooldowns from CooldownOverlay states
        if mCooldownOverlay then
            local cds = mCooldownOverlay:GetCooldownStates()
            for sid, cd in pairs(cds) do
                limitedState.cooldowns[sid] = cd.remaining or 0
            end
        end

        -- Populate inMeta from APLEngine state
        limitedState.inMeta = mAPLEngine:IsMetaActive()

        -- Populate targetCount and combatDuration from AIInference if available
        -- 同时读取 targetCount 和 timeSincePull，避免重复调用 GetContext()
        if mAIInference then
            local aiCtx = mAIInference:GetContext()
            if aiCtx then
                if aiCtx.targetCount then
                    currentTargetCount = aiCtx.targetCount
                end
                -- 传递战斗时长给 APLEngine 用于 opener 检测
                limitedState.combatDuration = aiCtx.timeSincePull or 0
            end
        end
        limitedState.targetCount = currentTargetCount

        -- Increase depth to 3 to get better lookahead for the prediction bar
        local ok, result = pcall(mAPLEngine.PredictNext, mAPLEngine, context.blizzSpell, limitedState, 3)
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
        finalQueue.cooldowns = finalQueue.cooldowns or {}
        wipe(finalQueue.cooldowns)
        local cIdx = 1
        -- GetCooldownStates() returns { [spellID] = {remaining, ready, texture, name, startTime, duration} }
        for spellID, cd in pairs(cds) do
            local isWhitelisted = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
            if isWhitelisted then
                if cd.ready then
                    context.cdReadyList[spellID] = true
                end
                -- 就绪和冷却中的大招都进入 cooldowns 列表供 CooldownBar 显示
                -- Include both ready and on-cooldown major CDs in the bar
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
    local candidates = candidates_reuse
    wipe(candidates)
    if context.blizzSpell and not PASSIVE_BLACKLIST[context.blizzSpell] and not RA:IsSpellPassive(context.blizzSpell) then
        candidates[context.blizzSpell] = true
    end
    if context.aplPred and context.aplPred.spellID then
        candidates[context.aplPred.spellID] = true
    end
    if context.defSpell then candidates[context.defSpell] = true end
    for sid, _ in pairs(context.cdReadyList) do candidates[sid] = true end

    -- Blind-spot detection: APL rules that are CD-ready but absent from Blizzard's rotation list
    -- 盲区检测：APL 中优先级较高且 CD 就绪、但 Blizzard 循环列表中缺失的技能
    if mAPLEngine and mAPLEngine:HasAPL() then
        local actionList = mAPLEngine:GetCurrentAPL()
        -- GetCurrentAPL returns the raw APL table; try to get a flat rule list
        local rules = nil
        if actionList then
            if actionList.rules then
                rules = actionList.rules
            elseif actionList.profiles then
                local profName = (mAPLEngine and mAPLEngine.GetProfileName)
                    and mAPLEngine:GetProfileName() or "default"
                local prof = actionList.profiles[profName] or actionList.profiles["default"]
                if prof then
                    if currentTargetCount >= 3 and prof.aoe then
                        rules = prof.aoe
                    else
                        rules = prof.singleTarget
                    end
                end
            end
        end
        if rules then
            local cdStates = mCooldownOverlay and mCooldownOverlay:GetCooldownStates() or {}
            for _, rule in ipairs(rules) do
                local sid = rule.spellID
                if sid and not rotationSpells[sid] then
                    -- 跳过未学习的天赋技能（避免因 unlearned spell CD = 0 被误判为就绪）
                    -- Skip unlearned talent spells (their CD returns 0, falsely appearing ready)
                    local isKnown = not IsPlayerSpell or IsPlayerSpell(sid)
                    if isKnown then
                        -- Check if the CD is actually ready in the overlay
                        local cdState = cdStates[sid]
                        if cdState and cdState.ready then
                            context.blindSpotCandidates[sid] = true
                            candidates[sid] = true
                        end
                    end
                end
            end
        end
    end

    for sid, _ in pairs(context.blindSpotCandidates) do candidates[sid] = true end

    -- 安全网：过滤掉已知在 CD 中的候选（除 Blizzard 推荐和 defensive 以外）
    -- Safety net: drop candidates known to be on cooldown (> 1.0s remaining).
    -- Blizzard rec and defensive are exempt (may have charge/proc info we lack).
    -- FIX (OverridePair): CD safety net now also checks paired override IDs.
    -- If either spell in a pair is on CD, remove BOTH from candidates.
    -- 覆盖对 CD 安全网：如果任一覆盖对技能在 CD 中，移除两者。
    if mCooldownOverlay then
        local cds = mCooldownOverlay:GetCooldownStates()
        wipe(toRemove_reuse)
        local toRemove = toRemove_reuse
        for sid, _ in pairs(candidates) do
            local onCD = false
            local cdState = cds[sid]
            if cdState then
                if not cdState.ready and cdState.remaining and cdState.remaining > 1.0 then
                    onCD = true
                end
            else
                -- FIX (Round14-Bug2): 未被 CooldownOverlay 追踪的技能，用 API 直接检查
                -- For spells not tracked by CooldownOverlay, fall back to direct API query
                onCD = IsSpellOnCooldown(sid)
            end
            -- Check paired override ID as well
            -- 同时检查覆盖对配对 ID
            if not onCD then
                local pairedID = RA.KNOWN_OVERRIDE_PAIRS and RA.KNOWN_OVERRIDE_PAIRS[sid]
                if pairedID then
                    local pairedState = cds[pairedID]
                    if pairedState and not pairedState.ready
                       and pairedState.remaining and pairedState.remaining > 1.0 then
                        onCD = true
                    end
                end
            end
            if onCD then
                -- Only exempt defensive spell
                -- 仅排除防御技能
                if sid ~= context.defSpell then
                    toRemove[#toRemove + 1] = sid
                    -- Also mark paired ID for removal if it's a candidate
                    -- 同时标记配对 ID 移除
                    local pairedID = RA.KNOWN_OVERRIDE_PAIRS and RA.KNOWN_OVERRIDE_PAIRS[sid]
                    if pairedID and candidates[pairedID] and pairedID ~= context.defSpell then
                        toRemove[#toRemove + 1] = pairedID
                    end
                end
            end
        end
        for _, sid in ipairs(toRemove) do
            candidates[sid] = nil
            context.blindSpotCandidates[sid] = nil
        end
    end

    -- 过滤被动技能（不可施放的技能不应成为推荐候选）
    -- Filter passive spells (non-castable spells must not appear as candidates)
    do
        wipe(passiveRemove_reuse)
        local passiveToRemove = passiveRemove_reuse
        for sid, _ in pairs(candidates) do
            if RA:IsSpellPassive(sid) or PASSIVE_BLACKLIST[sid] then
                passiveToRemove[#passiveToRemove + 1] = sid
            end
        end
        for _, sid in ipairs(passiveToRemove) do
            candidates[sid] = nil
            context.blindSpotCandidates[sid] = nil
        end
    end

    -- 软屏蔽：施放后 SOFT_BLOCK_DURATION 秒内，临时阻止刚施放技能被推荐
    -- Soft-block filter: suppress recently-cast spells until real CD data arrives.
    -- Exempts Blizzard rec and defensive spell in case of charges / procs.
    do
        local now = GetTime()
        wipe(sbRemove_reuse)
        local sbToRemove = sbRemove_reuse
        for sid, expiry in pairs(softBlockedSpells) do
            if now < expiry then
                if sid ~= context.blizzSpell and sid ~= context.defSpell then
                    sbToRemove[#sbToRemove + 1] = sid
                end
            end
        end
        for _, sid in ipairs(sbToRemove) do
            candidates[sid] = nil
            context.blindSpotCandidates[sid] = nil
        end
    end

    -- 过滤未学习的技能：动态检查玩家当前天赋，只推荐已学技能
    -- Filter unlearned spells: dynamically check current talents, only recommend known spells
    do
        wipe(unlearnedRemove_reuse)
        local unlearnedRemove = unlearnedRemove_reuse
        for sid, _ in pairs(candidates) do
            if IsPlayerSpell then
                local okK, isK = pcall(IsPlayerSpell, sid)
                if okK and not isK then
                    unlearnedRemove[#unlearnedRemove + 1] = sid
                end
            end
        end
        for _, sid in ipairs(unlearnedRemove) do
            candidates[sid] = nil
            context.blindSpotCandidates[sid] = nil
        end
    end

    -- 3. Score & Rank
    local scored = scored_reuse
    local nScored = 0
    for sid, _ in pairs(candidates) do
        local score, src = CalculateScore(sid, context, weights, aplPredictions)
        if score > 0 then
            nScored = nScored + 1
            if not scored[nScored] then scored[nScored] = {} end
            scored[nScored].spellID = sid
            scored[nScored].score = score
            scored[nScored].source = src
        end
    end
    for i = nScored + 1, #scored do
        scored[i] = nil
    end
    table.sort(scored, function(a, b) return a.score > b.score end)

    -- 【新增】最终安全网：对 scored 列表做 IsSpellRecommendable 验证
    -- Final safety net: validate scored entries with RA:IsSpellRecommendable
    -- 倒序遍历以安全移除不通过的条目
    for i = #scored, 1, -1 do
        if not RA:IsSpellRecommendable(scored[i].spellID) then
            table.remove(scored, i)
        end
    end

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

        -- 追踪主推荐是否变化（供其他系统使用）
        -- Track main spell change for other systems.
        local newMainID = finalQueue.main and finalQueue.main.spellID or nil
        if prevMainSpellID ~= newMainID then
            prevMainSpellID = newMainID
        end

        -- FIX (Bug1): Populate next[] using APL predictions (steps 2+) first,
        -- then fill remaining slots from scored candidates (rank 2+).
        -- 修复：优先用 APL 预测第 2、3步 填充 next[]，再补充 scored 排名第 2+ 的候选。
        local nIdx = 1

        -- Priority 1: APL predictions (steps 1 to 3)
        for i = 1, #aplPredictions do
            if nIdx > 5 then break end
            local sid = aplPredictions[i].spellID
            if IsSpellCastable(sid) then
                if not finalQueue.next[nIdx] then
                    finalQueue.next[nIdx] = { spellID = 0, confidence = 0 }
                end
                finalQueue.next[nIdx].spellID    = sid
                finalQueue.next[nIdx].confidence = aplPredictions[i].confidence or 0.7
                nIdx = nIdx + 1
            end
        end

        -- Priority 2: scored candidates rank 2+ (deduplicate against next[] internal entries)
        -- 去重逻辑：仅针对 next[] 内部去重，允许与 main 相同
        for i = 2, math.min(#scored, 6) do
            if nIdx > 5 then break end
            local sid = scored[i].spellID
            local dominated = false
            for j = 1, nIdx - 1 do
                if finalQueue.next[j] and finalQueue.next[j].spellID == sid then
                    dominated = true
                    break
                end
            end
            if not dominated then
                if not finalQueue.next[nIdx] then
                    finalQueue.next[nIdx] = { spellID = 0, confidence = 0 }
                end
                finalQueue.next[nIdx].spellID    = sid
                finalQueue.next[nIdx].confidence = math.min(1.0, scored[i].score / 1.5)
                nIdx = nIdx + 1
            end
        end

        -- Priority 3: NeuralPredictor 补充预测（当 APL + scored 不足时）
        -- NeuralPredictor 融合了决策树、Markov链和 Blizzard 推荐，作为兜底预测源
        if nIdx <= 3 and mNeuralPredictor then
            local npOk, npResult = pcall(mNeuralPredictor.GetCombinedPrediction, mNeuralPredictor)
            if npOk and npResult then
                -- 先尝试 primary（如果不在队列中）
                local npPrimary = npResult.primary
                if npPrimary and npPrimary.spellID and npPrimary.spellID ~= 0 then
                    if IsSpellCastable(npPrimary.spellID) then
                        local dominated = false
                        for j = 1, nIdx - 1 do
                            if finalQueue.next[j] and finalQueue.next[j].spellID == npPrimary.spellID then
                                dominated = true
                                break
                            end
                        end
                        if not dominated and nIdx <= 5 then
                            if not finalQueue.next[nIdx] then
                                finalQueue.next[nIdx] = { spellID = 0, confidence = 0 }
                            end
                            finalQueue.next[nIdx].spellID    = npPrimary.spellID
                            finalQueue.next[nIdx].confidence = npPrimary.confidence or 0.5
                            nIdx = nIdx + 1
                        end
                    end
                end
                -- 再添加 alternatives
                if npResult.alternatives then
                    for _, alt in ipairs(npResult.alternatives) do
                        if nIdx > 5 then break end
                        if IsSpellCastable(alt.spellID) then
                            local dominated = false
                            for j = 1, nIdx - 1 do
                                if finalQueue.next[j] and finalQueue.next[j].spellID == alt.spellID then
                                    dominated = true
                                    break
                                end
                            end
                            if not dominated then
                                if not finalQueue.next[nIdx] then
                                    finalQueue.next[nIdx] = { spellID = 0, confidence = 0 }
                                end
                                finalQueue.next[nIdx].spellID    = alt.spellID
                                finalQueue.next[nIdx].confidence = alt.confidence or 0.4
                                nIdx = nIdx + 1
                            end
                        end
                    end
                end
            end
        end

        -- 5. Anti-Flicker Logic for next[]
        -- 抗抖动处理：只有当预测变化持续两帧以上时才更新 UI
        for i = 1, 5 do
            local proposed = finalQueue.next[i] and finalQueue.next[i].spellID or 0
            local previous = previousNextSpells[i] or 0

            if proposed ~= previous then
                flickerCounters[i] = (flickerCounters[i] or 0) + 1
                if flickerCounters[i] >= FLICKER_THRESHOLD then
                    previousNextSpells[i] = proposed
                    flickerCounters[i] = 0
                else
                    -- Revert to previous to stabilize
                    if previous == 0 then
                        finalQueue.next[i] = nil
                    else
                        if not finalQueue.next[i] then
                            finalQueue.next[i] = { spellID = 0, confidence = 0.5 }
                        end
                        finalQueue.next[i].spellID = previous
                    end
                end
            else
                flickerCounters[i] = 0
            end
        end

        for i = nIdx, #finalQueue.next do
            finalQueue.next[i] = nil
        end

        -- 每次 AssembleQueue 都通知 UI 更新（放在填充 next[] 之后）
        -- Always fire AFTER filling next[] so the UI sees the complete data.
        local eh = RA:GetModule("EventHandler")
        if eh then eh:Fire("ROTAASSIST_QUEUE_UPDATED", finalQueue.main) end
    else
        -- FIX (Bug2): Also reset lastRecommendedSpellID when queue clears
        lastRecommendedSpellID = finalQueue.main and finalQueue.main.spellID or nil
        finalQueue.main = nil
        for i = 1, #finalQueue.next do finalQueue.next[i] = nil end
        wipe(previousNextSpells)
        wipe(flickerCounters)
        -- 队列清空：更新追踪值并无条件通知 UI
        -- Queue cleared: update tracking and always notify UI.
        if prevMainSpellID ~= nil then
            prevMainSpellID = nil
        end
        local eh = RA:GetModule("EventHandler")
        if eh then eh:Fire("ROTAASSIST_QUEUE_UPDATED", nil) end
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
    mNeuralPredictor  = RA:GetModule("NeuralPredictor")

    updateFrame:SetScript("OnUpdate", onUpdate)
    updateFrame:Show()

    -- Drive APLEngine meta-state from actual spell casts; also apply soft-block and
    -- force-refresh recommendation cache so the UI never lags behind a cast.
    -- 施法成功后：更新变身状态、软屏蔽、失效 Bridge 缓存、重建队列
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "SmartQueueManager", function(_, unit, _, spellID)
            if unit ~= "player" then return end

            -- 1. Update Metamorphosis state in APLEngine
            if mAPLEngine and mAPLEngine.SetMetaStateFromCast then
                mAPLEngine:SetMetaStateFromCast(spellID)
            end

            -- 2. Soft-block: suppress just-cast spell until SPELL_UPDATE_COOLDOWN confirms real CD.
            --    Only block spells with a meaningful CD (>= 3s) listed in WhitelistSpells.
            --    仅对 WhitelistSpells 中 cdSeconds >= 3 的技能启用软屏蔽
            -- FIX (OverridePair): Also soft-block the paired override ID.
            -- 同时对覆盖对技能施加软屏蔽（如施放 Death Sweep 后同时屏蔽 Blade Dance）。
            local wsInfo = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
            if wsInfo and wsInfo.cdSeconds and wsInfo.cdSeconds >= 3 then
                local blockExpiry = GetTime() + SOFT_BLOCK_DURATION
                softBlockedSpells[spellID] = blockExpiry
                local pairedID = RA.KNOWN_OVERRIDE_PAIRS and RA.KNOWN_OVERRIDE_PAIRS[spellID]
                if pairedID then
                    softBlockedSpells[pairedID] = blockExpiry
                end
            end

            -- 3. Invalidate the Bridge recommendation cache so the next call to
            --    GetCurrentRecommendation() fetches a fresh Blizzard spell.
            --    失效 Bridge 缓存，下次立刻拿到最新推荐
            if mBridge and mBridge.InvalidateCache then
                mBridge:InvalidateCache()
            end

            -- 4. Clear sticky Blizzard spell if we just cast it — unless it's a channeled
            --    spell. During a channel the sticky should keep showing what comes AFTER.
            --    引导技能施法后不清除 sticky，让引导期间继续显示下一步技能
            -- FIX (OverridePair): Also clear when paired ID matches (e.g. cast Death Sweep
            -- while sticky is Blade Dance).
            -- 覆盖对也清除 sticky（如 sticky 为 Blade Dance 但施放了 Death Sweep）。
            if lastKnownBlizzSpell then
                local shouldClear = (lastKnownBlizzSpell == spellID)
                if not shouldClear then
                    local pairedID = RA.KNOWN_OVERRIDE_PAIRS and RA.KNOWN_OVERRIDE_PAIRS[spellID]
                    if pairedID and lastKnownBlizzSpell == pairedID then
                        shouldClear = true
                    end
                end
                if shouldClear and not CHANNELED_SPELL_IDS[spellID] then
                    lastKnownBlizzSpell = nil
                end
            end

            -- 5. Trigger an immediate queue rebuild.
            --    立刻重建队列
            lastUpdate = THROTTLE_UPDATE
            AssembleQueue()
        end)

        -- 当 SPELL_UPDATE_COOLDOWN 触发时，真实 CD 数据已就绪：清除软屏蔽并立刻重建队列
        -- When real CD data arrives, clear soft-blocks and rebuild to reflect true CD state.
        eh:Subscribe("ROTAASSIST_CD_UPDATED", "SmartQueueManager", function()
            if next(softBlockedSpells) then
                wipe(softBlockedSpells)
                lastUpdate = THROTTLE_UPDATE
                AssembleQueue()
            end
        end)

        -- 引导开始：快照当前 APL 预测 step-1 的 spellID，作为引导期 sticky fallback
        -- Channel start: capture APL step-1 spellID so UI shows next-spell during channel.
        eh:Subscribe("ROTAASSIST_CHANNEL_START", "SmartQueueManager", function(_, unit)
            if unit ~= "player" then return end
            channelNextSpell = aplPredictions and aplPredictions[1]
                and aplPredictions[1].spellID or nil
        end)

        -- 引导结束或被打断时清除 channelNextSpell，恢复常规推荐逻辑
        -- Clear channelNextSpell on channel end or interrupt to resume normal logic.
        local function onChannelEnd()
            channelNextSpell = nil
        end
        eh:Subscribe("ROTAASSIST_SPELLCAST_STOP",        "SmartQueueManager_Chan", onChannelEnd)
        eh:Subscribe("ROTAASSIST_SPELLCAST_INTERRUPTED", "SmartQueueManager_Chan", onChannelEnd)
    end
end

function SmartQueueManager:OnDisable()
    if updateFrame then
        updateFrame:SetScript("OnUpdate", nil)
        updateFrame:Hide()
    end
    prevMainSpellID        = nil
    lastRecommendedSpellID = nil
    mNeuralPredictor       = nil
    for i = 1, #finalQueue.next do finalQueue.next[i] = nil end
    wipe(previousNextSpells)
    wipe(flickerCounters)
    finalQueue.main = nil
end
