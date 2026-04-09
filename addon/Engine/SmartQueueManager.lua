------------------------------------------------------------------------
-- RotaAssist - Smart Queue Manager
-- 譎ｺ閭ｽ髦溷・邂｡逅・勣 / Smart Queue Manager
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

-- 蟾ｲ遏･逧・｢ｫ蜉ｨ/荳榊庄譁ｽ謾ｾ謚閭ｽ鮟大錐蜊包ｼ・PI 譟･隸｢逧・ｿｫ騾溯ｷｯ蠕・､・ｻｽ・・
-- Known passive/non-castable spell blacklist (fast-path backup for API queries)
local PASSIVE_BLACKLIST = RA.Registry.PASSIVE_BLACKLIST

-- 謚玲竃蜉ｨ驟咲ｽｮ / Anti-flicker config
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
--- 譽譟･謚閭ｽ譏ｯ蜷ｦ蝨ｨ譛画譜 CD 荳ｭ・郁ｶ・ｿ・1.0遘抵ｼ会ｼ檎畑莠手ｿ・ｻ､ next[] 荳ｭ逧・｢・ｵ九・
--- FIX (OverridePair): Also checks the paired override ID (e.g. Death Sweep for Blade Dance).
--- 蜷梧慮譽譟･隕・尠蟇ｹ謚閭ｽ逧・CD 迥ｶ諤・ｼ亥ｦ・Blade Dance 竊・Death Sweep・峨・
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
            -- 隕・尠蟇ｹ譽譟･・壻ｸｻ ID 蟆ｱ扈ｪ譌ｶ譟･逵矩・蟇ｹ ID 譏ｯ蜷ｦ蝨ｨ CD
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
    -- 隕・尠蟇ｹ API 蝗樣・壻ｸｻ ID 譛ｪ蝨ｨ CD 譌ｶ譽譟･驟榊ｯｹ ID
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
    -- 12.0 secret value 蝗樣・壻ｻ取命豕募紙蜿ｲ隶ｰ蠖穂ｸｭ莨ｰ邂怜・蜊ｴ迥ｶ諤・
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
--- 扈滉ｸ蜿ｯ譁ｽ謾ｾ諤ｧ譽譟･・夊｢ｫ蜉ｨ縲∵悴蟄ｦ荵縲∽ｸ榊庄譁ｽ謾ｾ縲∝・蜊ｴ荳ｭ蝗幃㍾霑・ｻ､縲・
--- @param spellID number
--- @return boolean castable
local function IsSpellCastable(spellID)
    if not spellID or spellID == 0 then return false end
    -- 1. 陲ｫ蜉ｨ鮟大錐蜊募ｿｫ騾溯ｷｯ蠕・
    if PASSIVE_BLACKLIST[spellID] then return false end
    -- 2. RA 陲ｫ蜉ｨ譽豬・
    if RA.IsSpellPassive and RA:IsSpellPassive(spellID) then return false end
    -- 3. 譛ｪ蟄ｦ荵譽豬・
    if IsPlayerSpell then
        local okL, known = pcall(IsPlayerSpell, spellID)
        if okL and not known then return false end
    end
    -- 4. 荳榊庄譁ｽ謾ｾ譽豬具ｼ郁ｦ・尠 Hero Talent 蠅槫ｼｺ蝙玖｢ｫ蜉ｨ遲・IsSpellPassive 貍丞愛逧・ュ蜀ｵ・・
    if C_Spell and C_Spell.IsSpellUsable then
        local okU, usable = pcall(C_Spell.IsSpellUsable, spellID)
        if okU and usable == false then return false end
    end
    -- 5. 蜀ｷ蜊ｴ荳ｭ・・1.0遘抵ｼ・
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

-- 荳贋ｸ蟶ｧ荳ｻ謗ｨ闕蝕D・御ｾ・AccuracyTracker 蛛壻ｸ贋ｸ蟶ｧ豈泌ｯｹ縲・
local lastRecommendedSpellID = nil

-- Sticky Blizzard recommendation (caches last known ID if Blizzard temporarily returns nil)
-- 隶ｰ蠢・Blizzard 謗ｨ闕撰ｼ磯亟豁｢ GCD 謌門ｻｶ霑溷ｯｼ閾ｴ謗ｨ闕千椪髣ｴ豸亥､ｱ蠑戊ｵｷ鬚・ｵ区竃蜉ｨ・・
local lastKnownBlizzSpell = nil

-- 譁ｽ豕募錘逧・ｽｯ螻剰反・壼惠逵溷ｮ・CD 謨ｰ謐ｮ蛻ｰ譚･蜑堺ｸｴ譌ｶ髦ｻ豁｢蛻壽命謾ｾ逧・橿閭ｽ陲ｫ謗ｨ闕・
-- Soft-block: temporarily suppress the just-cast spell until SPELL_UPDATE_COOLDOWN confirms the real CD.
local softBlockedSpells = {}
local SOFT_BLOCK_DURATION = 0.6  -- seconds until soft-block auto-expires

-- 蠑募ｯｼ謚閭ｽ・壽命豕墓・蜉溷錘荳肴ｸ・勁 lastKnownBlizzSpell・御ｿ晄戟蠑募ｯｼ扈捺據蜷惹ｸ倶ｸ豁･謗ｨ闕千ｨｳ螳・
-- Channeled spells: don't clear sticky on success 窶・keep showing next-spell during channel.
local CHANNELED_SPELL_IDS = {
    [198013] = true,  -- Eye Beam (Havoc)
    [212084] = true,  -- Fel Devastation (Vengeance)
    [258920] = true,  -- Immolation Aura (channel phase)
}

-- 蠑募ｯｼ譛滄龍謐戊執逧・悟ｼ募ｯｼ扈捺據蜷惹ｸ倶ｸ豁･縲行pellID・檎畑莠・sticky fallback
-- Captured next-spell spellID during a channel, used as sticky fallback.
local channelNextSpell = nil

local context_reuse = { blizzSpell=nil, aplPred=nil, aplState=nil, cdReadyList={}, blindSpotCandidates={}, defSpell=nil, defUrgency=0, aiPhase="NORMAL", aiTip=nil }
local candidates_reuse = {}
local scored_reuse = {}
local toRemove_reuse = {}
local passiveRemove_reuse = {}
local sbRemove_reuse = {}
local unlearnedRemove_reuse = {}
-- 譛霑台ｸ蟶ｧ逧・APL 鬚・ｵ狗ｻ捺棡・域ｨ｡蝮礼ｺｧ・御ｾ・CHANNEL_START 髣ｭ蛹・ｯｻ蜿厄ｼ・
-- Most-recent APL predictions at module level so the CHANNEL_START closure can read them.
local aplPredictions = {}

------------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------------

---Calculate priority score for a spell candidate.
---隶｡邂怜咎画橿閭ｽ逧・ｼ伜・郤ｧ蠕怜・縲・
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
    -- Step-1 gets full APL weight, step-2 gets 0.5ﾃ・ step-3 gets 0.3ﾃ・
    -- Skip if already scored as a blind-spot to avoid double-counting.
    -- APL 蛻・ｱりｯ・・・夂ｬｬ1豁･蜈ｨ譚・㍾・檎ｬｬ2豁･0.5ﾃ暦ｼ檎ｬｬ3豁･0.3ﾃ暦ｼ帷峇蛹ｺ謚閭ｽ霍ｳ霑・∩蜈榊曙驥崎ｮ｡蛻・
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
    -- 逶ｲ蛹ｺ蜉蛻・ｼ哂PL 莨伜・郤ｧ霎・ｫ倅ｸ・Blizzard 蠕ｪ邇ｯ荳ｭ郛ｺ蟆醍噪蟆ｱ扈ｪ CD・悟ｾ怜・ >= 1.0 雜・ｶ・Blizzard
    if context.blindSpotCandidates and context.blindSpotCandidates[spellID] then
        score = score + 1.2  -- 蠢・｡ｻ雜・ｿ・Blizzard 逧・1.0・御ｽｿ逶ｲ蛹ｺ謚閭ｽ蜿ｯ莉･謌蝉ｸｺ荳ｻ謗ｨ闕・
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
        wipe(previousNextSpells)   -- 貂・ｩｺ謚玲竃蜉ｨ郛灘ｭ・
        wipe(flickerCounters)
        return
    end

    local weights = RA.db and RA.db.profile.smartQueue or defaultWeights

    -- 1. Gather Context
    local context = context_reuse
    context.blizzSpell = nil
    context.aplPred = nil
    context.aplState = nil
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
        -- 2. channelNextSpell  窶・captured at channel start (蠑募ｯｼ荳ｭ・壽仞遉ｺ蠑募ｯｼ蜷守噪荳倶ｸ荳ｪ謚閭ｽ)
        -- 3. lastKnownBlizzSpell 窶・normal inter-GCD sticky
        if context.blizzSpell then
            lastKnownBlizzSpell = context.blizzSpell
        elseif channelNextSpell then
            context.blizzSpell = channelNextSpell
        elseif lastKnownBlizzSpell then
            -- FIX (Round14-Bug1): sticky fallback 蠢・｡ｻ鬪瑚ｯ∵橿閭ｽ譏ｯ蜷ｦ莉咲┯蜿ｯ譁ｽ謾ｾ
            -- Sticky fallback must verify the spell is not on cooldown before reuse
            if not IsSpellOnCooldown(lastKnownBlizzSpell) then
                context.blizzSpell = lastKnownBlizzSpell
            else
                -- 謚閭ｽ蟾ｲ霑・CD・梧ｸ・勁 sticky・瑚ｮｩ髦溷・閾ｪ辟ｶ髯咲ｺｧ蛻ｰ APL/AI 謗ｨ闕・
                lastKnownBlizzSpell = nil
            end
        end
    end

    -- Build Blizzard rotation spell set for blind-spot detection
    -- Blizzard 蠕ｪ邇ｯ謚閭ｽ髮・粋・檎畑莠取｣豬狗峇蛹ｺ謚閭ｽ
    local rotationSpells = {}
    if mBridge then
        local list = mBridge:GetRotationSpells()
        for _, sid in ipairs(list) do
            rotationSpells[sid] = true
        end
    end

    -- FIX (Bug1): PredictNext returns an ARRAY of predictions.
    -- Parse it correctly; the first element joins scoring, rest go to next[].
    -- 菫ｮ螟搾ｼ啀redictNext 霑泌屓謨ｰ扈・ｼ檎ｬｬ荳荳ｪ蜈・ｴ蜿ゆｸ手ｯ・・・悟・菴吝｡ｫ蜈・next[]縲・
    -- Reset APL predictions array (module-level, reused across frames)
    -- 驥咲ｽｮ APL 鬚・ｵ区焚扈・ｼ域ｨ｡蝮礼ｺｧ・瑚ｷｨ蟶ｧ螟咲畑・・
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
            combatDuration  = 0,
            charges         = {},
            windows         = {},
            softBlocked     = softBlockedSpells,
        }

        -- Read the normalized SpecEnhancements resource config.
        -- 隸ｻ蜿也ｻ滉ｸ蜷守噪 SpecEnhancements 襍・ｺ宣・鄂ｮ縲・
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

        if C_Spell and C_Spell.GetSpellCharges and RA.WhitelistSpells then
            for sid in pairs(RA.WhitelistSpells) do
                local okCharges, chargeInfo = pcall(C_Spell.GetSpellCharges, sid)
                if okCharges and type(chargeInfo) == "table" and chargeInfo.currentCharges then
                    limitedState.charges[sid] = chargeInfo.currentCharges
                end
            end
        end

        -- Populate inMeta from APLEngine state
        limitedState.inMeta = mAPLEngine:IsMetaActive()

        -- Populate targetCount and combatDuration from AIInference if available
        -- 蜷梧慮隸ｻ蜿・targetCount 蜥・timeSincePull・碁∩蜈埼㍾螟崎ｰ・畑 GetContext()
        if mAIInference then
            local aiCtx = mAIInference:GetContext()
            if aiCtx then
                if aiCtx.targetCount then
                    currentTargetCount = aiCtx.targetCount
                end
                limitedState.combatDuration = aiCtx.timeSincePull or 0
                if aiCtx.windows then
                    limitedState.windows = aiCtx.windows
                end
            end
        end
        limitedState.targetCount = currentTargetCount
        context.aplState = limitedState

        -- Increase depth to 3 to get better lookahead for the prediction bar
        local ok, result = pcall(mAPLEngine.PredictNext, mAPLEngine, context.blizzSpell, limitedState, 3)
        if ok and type(result) == "table" then
            aplPredictions = result
        end
    end

    -- First APL prediction participates in scoring
    -- 隨ｬ荳荳ｪ APL 鬚・ｵ句盾荳惹ｸｻ謗ｨ闕占ｯ・・
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
                -- 蟆ｱ扈ｪ蜥悟・蜊ｴ荳ｭ逧・､ｧ諡幃・霑帛・ cooldowns 蛻苓｡ｨ萓・CooldownBar 譏ｾ遉ｺ
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
    -- 逶ｲ蛹ｺ譽豬具ｼ哂PL 荳ｭ莨伜・郤ｧ霎・ｫ倅ｸ・CD 蟆ｱ扈ｪ縲∽ｽ・Blizzard 蠕ｪ邇ｯ蛻苓｡ｨ荳ｭ郛ｺ螟ｱ逧・橿閭ｽ
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
                    -- 霍ｳ霑・悴蟄ｦ荵逧・､ｩ襍区橿閭ｽ・磯∩蜈榊屏 unlearned spell CD = 0 陲ｫ隸ｯ蛻､荳ｺ蟆ｱ扈ｪ・・
                    -- Skip unlearned talent spells (their CD returns 0, falsely appearing ready)
                    local isKnown = not IsPlayerSpell or IsPlayerSpell(sid)
                    if isKnown then
                        local stateOk = true
                        if rule.condition and mAPLEngine.EvaluateCondition and context.aplState then
                            local blindSpotState = {
                                cooldowns = context.aplState.cooldowns or {},
                                resource = context.aplState.resource or 0,
                                inMeta = context.aplState.inMeta or false,
                                lastCast = nil,
                                targetCount = context.aplState.targetCount or 1,
                                combatDuration = context.aplState.combatDuration or 0,
                                charges = context.aplState.charges or {},
                                windows = context.aplState.windows or {},
                            }
                            stateOk = mAPLEngine:EvaluateCondition(rule.condition, sid, blindSpotState)
                        end

                        -- Check if the CD is actually ready in the overlay
                        local cdState = cdStates[sid]
                        if stateOk and cdState and cdState.ready then
                            context.blindSpotCandidates[sid] = true
                            candidates[sid] = true
                        end
                    end
                end
            end
        end
    end

    for sid, _ in pairs(context.blindSpotCandidates) do candidates[sid] = true end

    -- 螳牙・鄂托ｼ夊ｿ・ｻ､謗牙ｷｲ遏･蝨ｨ CD 荳ｭ逧・咎会ｼ磯勁 Blizzard 謗ｨ闕仙柱 defensive 莉･螟厄ｼ・
    -- Safety net: drop candidates known to be on cooldown (> 1.0s remaining).
    -- Blizzard rec and defensive are exempt (may have charge/proc info we lack).
    -- FIX (OverridePair): CD safety net now also checks paired override IDs.
    -- If either spell in a pair is on CD, remove BOTH from candidates.
    -- 隕・尠蟇ｹ CD 螳牙・鄂托ｼ壼ｦよ棡莉ｻ荳隕・尠蟇ｹ謚閭ｽ蝨ｨ CD 荳ｭ・檎ｧｻ髯､荳､閠・・
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
                -- FIX (Round14-Bug2): 譛ｪ陲ｫ CooldownOverlay 霑ｽ雕ｪ逧・橿閭ｽ・檎畑 API 逶ｴ謗･譽譟･
                -- For spells not tracked by CooldownOverlay, fall back to direct API query
                onCD = IsSpellOnCooldown(sid)
            end
            -- Check paired override ID as well
            -- 蜷梧慮譽譟･隕・尠蟇ｹ驟榊ｯｹ ID
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
                -- 莉・賜髯､髦ｲ蠕｡謚閭ｽ
                if sid ~= context.defSpell then
                    toRemove[#toRemove + 1] = sid
                    -- Also mark paired ID for removal if it's a candidate
                    -- 蜷梧慮譬・ｮｰ驟榊ｯｹ ID 遘ｻ髯､
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

    -- 霑・ｻ､陲ｫ蜉ｨ謚閭ｽ・井ｸ榊庄譁ｽ謾ｾ逧・橿閭ｽ荳榊ｺ疲・荳ｺ謗ｨ闕仙咎会ｼ・
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

    -- 霓ｯ螻剰反・壽命謾ｾ蜷・SOFT_BLOCK_DURATION 遘貞・・御ｸｴ譌ｶ髦ｻ豁｢蛻壽命謾ｾ謚閭ｽ陲ｫ謗ｨ闕・
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

    -- 霑・ｻ､譛ｪ蟄ｦ荵逧・橿閭ｽ・壼勘諤∵｣譟･邇ｩ螳ｶ蠖灘燕螟ｩ襍具ｼ悟宵謗ｨ闕仙ｷｲ蟄ｦ謚閭ｽ
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

    -- 縲先眠蠅槭第怙扈亥ｮ牙・鄂托ｼ壼ｯｹ scored 蛻苓｡ｨ蛛・IsSpellRecommendable 鬪瑚ｯ・
    -- Final safety net: validate scored entries with RA:IsSpellRecommendable
    -- 蛟貞ｺ城″蜴・ｻ･螳牙・遘ｻ髯､荳埼夊ｿ・噪譚｡逶ｮ
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
        -- 菫晏ｭ俶立荳ｻ謗ｨ闕撰ｼ御ｾ・AccuracyTracker 蝨ｨ譁ｽ豕墓・蜉溷錘豈泌ｯｹ縲・
        lastRecommendedSpellID = finalQueue.main and finalQueue.main.spellID or nil

        finalQueue.main = {
            spellID    = scored[1].spellID,
            source     = scored[1].source,
            confidence = topConf
        }

        -- 霑ｽ雕ｪ荳ｻ謗ｨ闕先弍蜷ｦ蜿伜喧・井ｾ帛・莉也ｳｻ扈滉ｽｿ逕ｨ・・
        -- Track main spell change for other systems.
        local newMainID = finalQueue.main and finalQueue.main.spellID or nil
        if prevMainSpellID ~= newMainID then
            prevMainSpellID = newMainID
        end

        -- FIX (Bug1): Populate next[] using APL predictions (steps 2+) first,
        -- then fill remaining slots from scored candidates (rank 2+).
        -- 菫ｮ螟搾ｼ壻ｼ伜・逕ｨ APL 鬚・ｵ狗ｬｬ 2縲・豁･ 蝪ｫ蜈・next[]・悟・陦･蜈・scored 謗貞錐隨ｬ 2+ 逧・咎峨・
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
        -- 蜴ｻ驥埼ｻ霎托ｼ壻ｻ・宙蟇ｹ next[] 蜀・Κ蜴ｻ驥搾ｼ悟・隶ｸ荳・main 逶ｸ蜷・
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

        -- Priority 3: NeuralPredictor 陦･蜈・｢・ｵ具ｼ亥ｽ・APL + scored 荳崎ｶｳ譌ｶ・・
        -- NeuralPredictor 陞榊粋莠・・遲匁代｀arkov體ｾ蜥・Blizzard 謗ｨ闕撰ｼ御ｽ應ｸｺ蜈懷ｺ暮｢・ｵ区ｺ・
        if nIdx <= 3 and mNeuralPredictor then
            local npOk, npResult = pcall(mNeuralPredictor.GetCombinedPrediction, mNeuralPredictor)
            if npOk and npResult then
                -- 蜈亥ｰ晁ｯ・primary・亥ｦよ棡荳榊惠髦溷・荳ｭ・・
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
                -- 蜀肴ｷｻ蜉 alternatives
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
        -- 謚玲竃蜉ｨ螟・炊・壼宵譛牙ｽ馴｢・ｵ句序蛹匁戟扈ｭ荳､蟶ｧ莉･荳頑慮謇肴峩譁ｰ UI
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

        -- 豈乗ｬ｡ AssembleQueue 驛ｽ騾夂衍 UI 譖ｴ譁ｰ・域叛蝨ｨ蝪ｫ蜈・next[] 荵句錘・・
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
        -- 髦溷・貂・ｩｺ・壽峩譁ｰ霑ｽ雕ｪ蛟ｼ蟷ｶ譌譚｡莉ｶ騾夂衍 UI
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
---闔ｷ蜿匁怙扈井ｼ伜・謗貞ｺ冗噪鬚・ｵ矩弌蛻励・
---@return table
function SmartQueueManager:GetFinalQueue()
    return finalQueue
end

---Get the main spell ID that was recommended in the *previous* frame.
---Returns nil if there was no prior recommendation or the queue was empty.
---闔ｷ蜿紋ｸ贋ｸ蟶ｧ逧・ｸｻ謗ｨ闕先橿閭ｽ ID・檎畑莠取命豕墓・蜉溷錘豈泌ｯｹ蜃・｡ｮ蠎ｦ縲・
---@return number|nil spellID
function SmartQueueManager:GetLastRecommendedSpellID()
    return lastRecommendedSpellID
end

---Backward compatible wrapper for existing UI modules expecting RecommendationManager:GetDisplayData()
---荳ｺ譛滓悍莉・RecommendationManager 諡ｿ蛻ｰ邀ｻ莨ｼ譬ｼ蠑乗焚謐ｮ逧・立 UI 讓｡蝮玲署萓帛・螳ｹ縲・
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
    -- 譁ｽ豕墓・蜉溷錘・壽峩譁ｰ蜿倩ｺｫ迥ｶ諤√∬ｽｯ螻剰反縲∝､ｱ謨・Bridge 郛灘ｭ倥・㍾蟒ｺ髦溷・
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
            --    莉・ｯｹ WhitelistSpells 荳ｭ cdSeconds >= 3 逧・橿閭ｽ蜷ｯ逕ｨ霓ｯ螻剰反
            -- FIX (OverridePair): Also soft-block the paired override ID.
            -- 蜷梧慮蟇ｹ隕・尠蟇ｹ謚閭ｽ譁ｽ蜉霓ｯ螻剰反・亥ｦよ命謾ｾ Death Sweep 蜷主酔譌ｶ螻剰反 Blade Dance・峨・
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
            --    螟ｱ謨・Bridge 郛灘ｭ假ｼ御ｸ区ｬ｡遶句綾諡ｿ蛻ｰ譛譁ｰ謗ｨ闕・
            if mBridge and mBridge.InvalidateCache then
                mBridge:InvalidateCache()
            end

            -- 4. Clear sticky Blizzard spell if we just cast it 窶・unless it's a channeled
            --    spell. During a channel the sticky should keep showing what comes AFTER.
            --    蠑募ｯｼ謚閭ｽ譁ｽ豕募錘荳肴ｸ・勁 sticky・瑚ｮｩ蠑募ｯｼ譛滄龍扈ｧ扈ｭ譏ｾ遉ｺ荳倶ｸ豁･謚閭ｽ
            -- FIX (OverridePair): Also clear when paired ID matches (e.g. cast Death Sweep
            -- while sticky is Blade Dance).
            -- 隕・尠蟇ｹ荵滓ｸ・勁 sticky・亥ｦ・sticky 荳ｺ Blade Dance 菴・命謾ｾ莠・Death Sweep・峨・
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
            --    遶句綾驥榊ｻｺ髦溷・
            lastUpdate = THROTTLE_UPDATE
            AssembleQueue()
        end)

        -- 蠖・SPELL_UPDATE_COOLDOWN 隗ｦ蜿第慮・檎悄螳・CD 謨ｰ謐ｮ蟾ｲ蟆ｱ扈ｪ・壽ｸ・勁霓ｯ螻剰反蟷ｶ遶句綾驥榊ｻｺ髦溷・
        -- When real CD data arrives, clear soft-blocks and rebuild to reflect true CD state.
        eh:Subscribe("ROTAASSIST_CD_UPDATED", "SmartQueueManager", function()
            if next(softBlockedSpells) then
                wipe(softBlockedSpells)
                lastUpdate = THROTTLE_UPDATE
                AssembleQueue()
            end
        end)

        -- 蠑募ｯｼ蠑蟋具ｼ壼ｿｫ辣ｧ蠖灘燕 APL 鬚・ｵ・step-1 逧・spellID・御ｽ應ｸｺ蠑募ｯｼ譛・sticky fallback
        -- Channel start: capture APL step-1 spellID so UI shows next-spell during channel.
        eh:Subscribe("ROTAASSIST_CHANNEL_START", "SmartQueueManager", function(_, unit)
            if unit ~= "player" then return end
            channelNextSpell = aplPredictions and aplPredictions[1]
                and aplPredictions[1].spellID or nil
        end)

        -- 蠑募ｯｼ扈捺據謌冶｢ｫ謇捺妙譌ｶ貂・勁 channelNextSpell・梧△螟榊ｸｸ隗・耳闕宣ｻ霎・
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
