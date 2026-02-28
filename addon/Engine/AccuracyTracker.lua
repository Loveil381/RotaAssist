------------------------------------------------------------------------
-- RotaAssist - AccuracyTracker Engine
-- 准确率追踪器 / Accuracy Tracker
-- Tracks how well the player follows Blizzard's recommendations
-- and RotaAssist's predictions.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local AccuracyTracker = {}
RA:RegisterModule("AccuracyTracker", AccuracyTracker)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

local MAX_HISTORY = 100 -- 历史记录上限 (FIFO)

-- Current session stats
local sessionActive = false
local sessionStats = {
    totalCasts      = 0,
    blizzardMatches = 0,
    smartMatches    = 0,
    perPhase        = {}
}
local sessionStartTime = 0

------------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------------

---Check if a spell triggers/is a GCD spell.
---@param spellID number
---@return boolean
local function IsGCDSpell(spellID)
    local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, spellID)
    if not ok or not cdInfo then return false end
    if type(cdInfo) ~= "table" then return false end
    
    -- WOW 12.0 SECRET VALUE SAFE: check if isOnGCD is secret
    if cdInfo.isOnGCD ~= nil then 
        if issecretvalue(cdInfo.isOnGCD) then return true end -- 保守估计为 GCD 技能
        return true 
    end
    
    if spellID == 6603 then return false end -- Filter auto-attack
    return true
end

---Generate a star rating string based on accuracy percentage.
---根据胜率生成星级。
---@param acc number
---@return string stars, string verb
local function GetRatingDetails(acc)
    if acc >= 95.0 then return "★★★★★", "Perfect"
    elseif acc >= 85.0 then return "★★★★☆", "Excellent"
    elseif acc >= 70.0 then return "★★★☆☆", "Good"
    elseif acc >= 50.0 then return "★★☆☆☆", "Fair"
    else return "★☆☆☆☆", "Needs Practice" end
end

------------------------------------------------------------------------
-- Core Logic
------------------------------------------------------------------------

local function OnSpellCastSucceeded(_, unit, _, spellID)
    if unit ~= "player" or not sessionActive then return end
    if not IsGCDSpell(spellID) then return end

    sessionStats.totalCasts = sessionStats.totalCasts + 1

    -- FIX (Bug2): Check Blizzard match against BOTH current and previous
    -- recommendation, because the Blizzard recommendation may update to the
    -- *next* spell in the same frame that the cast completes.
    -- 修复：同时比对当前和上一帧 Blizzard 推荐，避免因推荐更新过快导致永远不匹配。
    local bridge = RA:GetModule("AssistedCombatBridge")
    if bridge then
        local matched = false

        -- Check current recommendation
        local rec = bridge:GetCurrentRecommendation()
        if rec and rec.spellID then
            if rec.spellID == spellID then
                matched = true
            else
                -- Name-based fuzzy match for variant spell IDs (same spell, different ranks)
                local ok1, info1 = pcall(C_Spell.GetSpellInfo, spellID)
                if ok1 and info1 and info1.name and info1.name == rec.name then
                    matched = true
                end
            end
        end

        -- FIX (Bug2): Also check previous recommendation if current didn't match
        -- 上一帧推荐也算匹配（Blizzard推荐在施法成功瞬间可能已更新）
        if not matched and bridge.GetPreviousRecommendation then
            local prevRec = bridge:GetPreviousRecommendation()
            if prevRec and prevRec.spellID == spellID then
                matched = true
            end
        end

        if matched then
            sessionStats.blizzardMatches = sessionStats.blizzardMatches + 1
        end
    end

    -- FIX (Bug2): Check SmartQueue match against BOTH current and last-frame
    -- main recommendation. SmartQueueManager updates faster than spell cast
    -- events, so lastRecommendedSpellID captures the "pre-cast" state.
    -- 修复：同时比对当前推荐和上一帧推荐，避免 SmartQueue 在施法成功前已更新。
    local smartQ = RA:GetModule("SmartQueueManager")
    if smartQ then
        local qData = smartQ:GetFinalQueue()
        local currentMain = qData and qData.main and qData.main.spellID
        local lastMain = smartQ.GetLastRecommendedSpellID
            and smartQ:GetLastRecommendedSpellID()

        if currentMain == spellID or lastMain == spellID then
            sessionStats.smartMatches = sessionStats.smartMatches + 1
        end
    end

    -- Phase tracking
    local patDet = RA:GetModule("PatternDetector")
    if patDet then
        local phaseData = patDet:GetPhase()
        local phase = phaseData and phaseData.phase or "UNKNOWN"
        if not sessionStats.perPhase[phase] then
            sessionStats.perPhase[phase] = { casts = 0, blizzMatches = 0, smartMatches = 0 }
        end
        local pStats = sessionStats.perPhase[phase]
        pStats.casts = pStats.casts + 1

        -- FIX (Bug2): Phase stats also use last-frame comparison
        -- 阶段统计同样使用上一帧比对逻辑
        if bridge then
            local rec = bridge:GetCurrentRecommendation()
            local prevRec = bridge.GetPreviousRecommendation and bridge:GetPreviousRecommendation()
            local blizzMatch = (rec and rec.spellID == spellID)
                or (prevRec and prevRec.spellID == spellID)
            if blizzMatch then
                pStats.blizzMatches = pStats.blizzMatches + 1
            end
        end
        if smartQ then
            local qData = smartQ:GetFinalQueue()
            local currentMain = qData and qData.main and qData.main.spellID
            local lastMain = smartQ.GetLastRecommendedSpellID
                and smartQ:GetLastRecommendedSpellID()
            if currentMain == spellID or lastMain == spellID then
                pStats.smartMatches = pStats.smartMatches + 1
            end
        end
    end
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get current session stats.
---获取本次会话统计。
---@return table
function AccuracyTracker:GetSessionStats()
    local bPct = sessionStats.totalCasts > 0 and (sessionStats.blizzardMatches / sessionStats.totalCasts * 100) or 0
    local sPct = sessionStats.totalCasts > 0 and (sessionStats.smartMatches / sessionStats.totalCasts * 100) or 0
    return {
        totalCasts       = sessionStats.totalCasts,
        blizzardMatches  = sessionStats.blizzardMatches,
        blizzardAccuracy = bPct,
        smartMatches     = sessionStats.smartMatches,
        smartAccuracy    = sPct,
        perPhase         = sessionStats.perPhase
    }
end

---Get historical trend from SavedVariables.
---从 SavedVariables 读取历史趋势。
---@return table[]
function AccuracyTracker:GetHistoricalTrend()
    -- FIX (nil protection): guard against RA.db not yet initialised
    -- 防御：RA.db 或 accuracyHistory 尚未初始化时返回空表
    local history = RA.db
        and RA.db.profile
        and RA.db.profile.accuracyHistory
        or {}
    return history
end

---Print accuracy history to chat.
---将准确度历史打印到聊天框。
function AccuracyTracker:PrintHistory()
    -- FIX (nil protection): guard against RA.db.profile.accuracy.history not existing
    -- 防御：第一次执行 /ra accuracy 时 history 可能还不存在
    local history = RA.db
        and RA.db.profile
        and RA.db.profile.accuracyHistory
        or {}

    RA:Print("--- RotaAssist Accuracy History ---")
    if #history == 0 then
        RA:Print("No records yet.")
    else
        for i = 1, math.min(10, #history) do
            local r = history[i]
            local s = GetRatingDetails(r.smartAccuracy)
            RA:Print(string.format("#%d [%s]: Smart %.1f%% / Blizz %.1f%% %s",
                i, date("%m/%d %H:%M", r.date), r.smartAccuracy, r.blizzardAccuracy, s))
        end
    end
    RA:Print("-----------------------------------")
end

---Reset session counters.
---重置会话计数。
function AccuracyTracker:Reset()
    sessionStats = {
        totalCasts      = 0,
        blizzardMatches = 0,
        smartMatches    = 0,
        perPhase        = {}
    }
end

---Save session summary to SavedVariables.
---保存会话总结。
function AccuracyTracker:SaveSession()
    if not sessionActive then return end
    sessionActive = false

    local combatDuration = GetTime() - sessionStartTime
    if combatDuration < 5 or sessionStats.totalCasts == 0 then return end

    local stats  = self:GetSessionStats()
    local specID = 0
    local specDet = RA:GetModule("SpecDetector")
    if specDet then specID = specDet:GetSpecID() or 0 end

    local record = {
        date            = time(),
        specID          = specID,
        duration        = combatDuration,
        casts           = stats.totalCasts,
        blizzardAccuracy = stats.blizzardAccuracy,
        smartAccuracy   = stats.smartAccuracy
    }

    if RA.db then
        RA.db.profile.accuracyHistory = RA.db.profile.accuracyHistory or {}
        local history = RA.db.profile.accuracyHistory
        table.insert(history, 1, record)
        while #history > MAX_HISTORY do
            table.remove(history)
        end
    end

    local stars = GetRatingDetails(stats.smartAccuracy)
    local L = RA.L
    local msg = string.format("[RotaAssist] %s - Smart Queue: %.1f%% (%d/%d) %s",
        L and L["COMBAT_ENDED"] or "Combat ended",
        stats.smartAccuracy, stats.smartMatches, stats.totalCasts, stars)
    RA:Print(msg)
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function AccuracyTracker:OnInitialize()
    -- Nothing to setup explicitly here
end

function AccuracyTracker:OnEnable()
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("PLAYER_REGEN_DISABLED", "AccuracyTracker", function()
            self:Reset()
            sessionActive     = true
            sessionStartTime  = GetTime()
        end)
        eh:Subscribe("PLAYER_REGEN_ENABLED", "AccuracyTracker", function()
            self:SaveSession()
        end)
        eh:Subscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "AccuracyTracker", OnSpellCastSucceeded)
    end
end

function AccuracyTracker:OnDisable()
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Unsubscribe("PLAYER_REGEN_DISABLED",            "AccuracyTracker")
        eh:Unsubscribe("PLAYER_REGEN_ENABLED",             "AccuracyTracker")
        eh:Unsubscribe("ROTAASSIST_SPELLCAST_SUCCEEDED",   "AccuracyTracker")
    end
    sessionActive = false
end
