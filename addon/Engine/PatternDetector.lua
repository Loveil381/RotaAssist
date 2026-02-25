------------------------------------------------------------------------
-- RotaAssist - Pattern Detector
-- 战斗阶段检测器 / Combat Phase Detector
-- Detects combat phase (AOE, BURST, EXECUTE, etc.) using ONLY
-- non-secret signals available in WoW 12.0.
-- 非シークレットシグナルのみで戦闘フェーズを判別する。
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local PatternDetector = {}
RA:RegisterModule("PatternDetector", PatternDetector)

------------------------------------------------------------------------
-- Phase Enum
------------------------------------------------------------------------

PatternDetector.PHASE = {
    PREPULL         = "PREPULL",
    OPENER          = "OPENER",
    NORMAL          = "NORMAL",
    AOE             = "AOE",
    BURST_PREPARE   = "BURST_PREPARE",
    BURST_ACTIVE    = "BURST_ACTIVE",
    BURST_COOLDOWN  = "BURST_COOLDOWN",
    RESOURCE_STARVED= "RESOURCE_STARVED",
    RESOURCE_CAP    = "RESOURCE_CAP",
    EXECUTE         = "EXECUTE",
    EMERGENCY       = "EMERGENCY",
    UNKNOWN         = "UNKNOWN",
}

------------------------------------------------------------------------
-- Constants & Throttles
------------------------------------------------------------------------

local THROTTLE_UPDATE     = 0.3  -- 推断间隔 / inference interval
local THROTTLE_NAMEPLATE  = 0.5  -- 姓名板缓存 / nameplate cache duration
local MAX_NAMEPLATES      = 40
local RESOURCE_SAMPLE_CAP = 10   -- 资源趋势样本数 / resource trend sample count
local MIN_PHASE_WEIGHT    = 0.4  -- 最低置信阈值 / minimum confidence threshold

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

local currentPhase = { phase = "PREPULL", confidence = 1.0, signals = {} }
local combatStartTime = 0
local updateFrame = nil
local lastUpdate = 0

-- Nameplate cache
local cachedNameplateCount = 0
local lastNameplateScan = 0

-- Resource trend ring buffer
local resourceSamples = {}
local resourceSampleHead = 0
local resourceSampleCount = 0

-- Spec data cache
local specData = nil

------------------------------------------------------------------------
-- Helper: Array contains
------------------------------------------------------------------------

local function ArrayContains(array, val)
    if not array then return false end
    for _, v in ipairs(array) do
        if v == val then return true end
    end
    return false
end

------------------------------------------------------------------------
-- Signal Collectors (全部使用非 SECRET API)
------------------------------------------------------------------------

---Count hostile nameplates on screen (cached 0.5s).
---可视敌方姓名板计数（0.5秒缓存）。
---@return number count
function PatternDetector:GetNameplateCount()
    local now = GetTime()
    if (now - lastNameplateScan) < THROTTLE_NAMEPLATE then
        return cachedNameplateCount
    end
    lastNameplateScan = now
    local cnt = 0
    for i = 1, MAX_NAMEPLATES do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            cnt = cnt + 1
        end
    end
    cachedNameplateCount = math.max(1, cnt)
    return cachedNameplateCount
end

---Get Blizzard's current recommendation spellID.
---获取暴雪当前推荐技能ID。
---@return number|nil spellID
local function GetBlizzardRecommendation()
    local bridge = RA:GetModule("AssistedCombatBridge")
    if not bridge then return nil end
    local rec = bridge:GetCurrentRecommendation()
    return rec and rec.spellID or nil
end

---Get secondary resource value (non-secret).
---获取次要资源值（非 SECRET）。
---@return number current, number max
local function GetSecondaryResource()
    if not specData or not specData.secondaryPowerType then return 0, 1 end
    local ok1, cur = pcall(UnitPower, "player", specData.secondaryPowerType)
    local ok2, mx  = pcall(UnitPowerMax, "player", specData.secondaryPowerType)
    return (ok1 and cur) or 0, (ok2 and mx and mx > 0 and mx) or 1
end

---Get last N spellIDs from CastHistoryRecorder.
---从施法记录器获取最近N个技能ID。
---@param n number
---@return number[] spellIDs
local function GetRecentCastIDs(n)
    local result = {}
    local recorder = RA:GetModule("CastHistoryRecorder")
    if not recorder then return result end
    for i = 1, n do
        result[i] = recorder:GetNthLastSpellID(i)
    end
    return result
end

---Get combat duration.
---获取战斗持续时间。
---@return number seconds
local function GetCombatDuration()
    if combatStartTime == 0 then return 0 end
    return GetTime() - combatStartTime
end

------------------------------------------------------------------------
-- Resource Trend (线性回归 / linear regression on secondary resource)
------------------------------------------------------------------------

---Record a secondary resource sample.
---记录一次次要资源样本。
local function RecordResourceSample()
    local cur, mx = GetSecondaryResource()
    resourceSampleHead = resourceSampleHead + 1
    if resourceSampleHead > RESOURCE_SAMPLE_CAP then resourceSampleHead = 1 end
    if not resourceSamples[resourceSampleHead] then
        resourceSamples[resourceSampleHead] = { 0, 0 }
    end
    resourceSamples[resourceSampleHead][1] = GetTime()
    resourceSamples[resourceSampleHead][2] = mx > 0 and (cur / mx) or 0
    resourceSampleCount = math.min(resourceSampleCount + 1, RESOURCE_SAMPLE_CAP)
end

---Get resource trend: "rising", "falling", or "stable".
---获取资源趋势："rising"、"falling" 或 "stable"。
---@return string trend
function PatternDetector:GetResourceTrend()
    if resourceSampleCount < 3 then return "stable" end
    -- 简单线性回归 / simple linear regression on normalized values
    local sumX, sumY, sumXY, sumXX = 0, 0, 0, 0
    local n = resourceSampleCount
    local ptr = resourceSampleHead
    for i = 1, n do
        if ptr < 1 then ptr = RESOURCE_SAMPLE_CAP end
        local s = resourceSamples[ptr]
        if s then
            local x = i
            local y = s[2]
            sumX = sumX + x
            sumY = sumY + y
            sumXY = sumXY + x * y
            sumXX = sumXX + x * x
        end
        ptr = ptr - 1
    end
    local denom = (n * sumXX - sumX * sumX)
    if denom == 0 then return "stable" end
    local slope = (n * sumXY - sumX * sumY) / denom
    if slope > 0.02 then return "rising"
    elseif slope < -0.02 then return "falling"
    else return "stable" end
end

------------------------------------------------------------------------
-- Phase Detection (多信号加权投票 / multi-signal weighted voting)
------------------------------------------------------------------------

local function DetectPhase()
    if not InCombatLockdown() then
        return { phase = "PREPULL", confidence = 1.0, signals = {} }
    end

    local combatDur   = GetCombatDuration()
    local npCount     = PatternDetector:GetNameplateCount()
    local blizzRec    = GetBlizzardRecommendation()
    local resCur, resMax = GetSecondaryResource()
    local resPct      = resMax > 0 and (resCur / resMax) or 0
    local recentCasts = GetRecentCastIDs(5)

    -- 权重桶 / weight buckets
    local scores = {}
    for _, v in pairs(PatternDetector.PHASE) do scores[v] = 0 end

    -- OPENER (战斗开始6秒内)
    if combatDur < 6 then
        scores["OPENER"] = 1.0
    end

    -- AOE (多目标)
    if npCount >= 3 then scores["AOE"] = scores["AOE"] + 0.5
    elseif npCount == 2 then scores["AOE"] = scores["AOE"] + 0.2 end
    if specData and ArrayContains(specData.aoeSpells, blizzRec) then
        scores["AOE"] = scores["AOE"] + 0.3
    end
    local aoeInRecent = 0
    for _, sid in ipairs(recentCasts) do
        if specData and ArrayContains(specData.aoeSpells, sid) then aoeInRecent = aoeInRecent + 1 end
    end
    if aoeInRecent >= 2 then scores["AOE"] = scores["AOE"] + 0.2 end

    -- RESOURCE_CAP (资源溢出)
    if resPct > 0.85 then scores["RESOURCE_CAP"] = scores["RESOURCE_CAP"] + 0.7 end
    if specData and ArrayContains(specData.spenderSpells, blizzRec) then
        scores["RESOURCE_CAP"] = scores["RESOURCE_CAP"] + 0.3
    end

    -- RESOURCE_STARVED (资源匮乏)
    if resPct < 0.15 then scores["RESOURCE_STARVED"] = scores["RESOURCE_STARVED"] + 0.7 end
    if specData and ArrayContains(specData.generatorSpells, blizzRec) then
        scores["RESOURCE_STARVED"] = scores["RESOURCE_STARVED"] + 0.3
    end

    -- BURST_ACTIVE (爆发激活 — 最近施放了大CD)
    if specData and specData.burstIndicatorSpells then
        if ArrayContains(specData.burstIndicatorSpells, blizzRec) then
            scores["BURST_ACTIVE"] = scores["BURST_ACTIVE"] + 0.4
        end
        for _, sid in ipairs(recentCasts) do
            if specData.burstCooldownSpell and sid == specData.burstCooldownSpell then
                scores["BURST_ACTIVE"] = scores["BURST_ACTIVE"] + 0.6
                break
            end
        end
    end

    -- BURST_PREPARE (即将爆发 — 暴雪推荐大CD)
    if specData and specData.majorCooldowns then
        for _, cd in ipairs(specData.majorCooldowns) do
            if cd.spellID == blizzRec then
                scores["BURST_PREPARE"] = scores["BURST_PREPARE"] + 0.4
                break
            end
        end
    end
    -- 白名单CD就绪检测 / whitelisted CD readiness
    if specData and specData.burstCooldownSpell then
        local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, specData.burstCooldownSpell)
        if ok and cdInfo and type(cdInfo) == "table" then
            local remaining = cdInfo.duration - (GetTime() - cdInfo.startTime)
            if remaining <= 0 then
                scores["BURST_PREPARE"] = scores["BURST_PREPARE"] + 0.3
            elseif remaining < 5 then
                scores["BURST_PREPARE"] = scores["BURST_PREPARE"] + 0.2
            end
        end
    end

    -- EXECUTE (斩杀 — 从推荐推断)
    if specData and specData.executeSpells then
        if ArrayContains(specData.executeSpells, blizzRec) then
            scores["EXECUTE"] = scores["EXECUTE"] + 0.8
        end
        for _, sid in ipairs(recentCasts) do
            if ArrayContains(specData.executeSpells, sid) then
                scores["EXECUTE"] = scores["EXECUTE"] + 0.2
                break
            end
        end
    end

    -- 选出最高分阶段 / pick highest scoring phase
    local bestPhase = "NORMAL"
    local bestScore = 0
    for phase, score in pairs(scores) do
        if score > bestScore then
            bestScore = score
            bestPhase = phase
        end
    end

    if bestScore < MIN_PHASE_WEIGHT then
        bestPhase = "NORMAL"
        bestScore = 1.0
    end

    return {
        phase = bestPhase,
        confidence = math.min(1.0, bestScore),
        signals = {
            nameplates = npCount,
            blizzRec = blizzRec,
            resPct = resPct,
            combatDur = combatDur
        }
    }
end

------------------------------------------------------------------------
-- Update Loop
------------------------------------------------------------------------

local function OnUpdate(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < THROTTLE_UPDATE then return end
    lastUpdate = 0

    RecordResourceSample()

    local newPhase = DetectPhase()
    local changed = newPhase.phase ~= currentPhase.phase
    currentPhase = newPhase

    if changed then
        local eh = RA:GetModule("EventHandler")
        if eh then
            eh:Fire("ROTAASSIST_PHASE_CHANGED", currentPhase.phase, currentPhase.confidence)
        end
    end
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get current detected phase.
---获取当前检测到的阶段。
---@return table {phase, confidence, signals}
function PatternDetector:GetPhase()
    return currentPhase
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function PatternDetector:OnInitialize()
    updateFrame = CreateFrame("Frame")
    updateFrame:Hide()
    -- 预分配资源样本 / pre-allocate resource samples
    for i = 1, RESOURCE_SAMPLE_CAP do
        resourceSamples[i] = { 0, 0 }
    end
end

function PatternDetector:OnEnable()
    -- 加载专精数据 / load spec enhancement data
    local function loadSpecData()
        local sd = RA:GetModule("SpecDetector")
        if not sd then return end
        local spec = sd:GetCurrentSpec()
        if spec and RA.SpecEnhancements and RA.SpecEnhancements[spec.specID] then
            local enh = RA.SpecEnhancements[spec.specID]
            -- 统一 inferenceRules 和顶级字段 / merge inferenceRules with top-level fields
            specData = enh.inferenceRules or {}
            specData.majorCooldowns = enh.majorCooldowns
            specData.executeSpells = enh.executeSpells or specData.executeSpells
            specData.secondaryPowerType = enh.secondaryPowerType
            specData.burstCooldownSpell = specData.burstCooldownSpell or
                (enh.burstWindows and enh.burstWindows.meta and enh.burstWindows.meta.trigger)
        end
    end

    loadSpecData()

    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("PLAYER_REGEN_DISABLED", "PatternDetector", function()
            combatStartTime = GetTime()
            resourceSampleHead = 0
            resourceSampleCount = 0
            currentPhase = { phase = "OPENER", confidence = 1.0, signals = {} }
            updateFrame:SetScript("OnUpdate", OnUpdate)
            updateFrame:Show()
        end)

        eh:Subscribe("PLAYER_REGEN_ENABLED", "PatternDetector", function()
            combatStartTime = 0
            currentPhase = { phase = "PREPULL", confidence = 1.0, signals = {} }
            updateFrame:SetScript("OnUpdate", nil)
            updateFrame:Hide()
        end)

        eh:Subscribe("ROTAASSIST_SPEC_CHANGED", "PatternDetector", loadSpecData)
    end

    if InCombatLockdown() then
        combatStartTime = GetTime()
        updateFrame:SetScript("OnUpdate", OnUpdate)
        updateFrame:Show()
    end
end

function PatternDetector:OnDisable()
    if updateFrame then
        updateFrame:SetScript("OnUpdate", nil)
        updateFrame:Hide()
    end
end
