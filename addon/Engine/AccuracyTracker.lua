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
    totalCasts = 0,
    blizzardMatches = 0,
    smartMatches = 0,
    perPhase = {}
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
    -- WOW 12.0 SECRET VALUE SAFE: isOnGCD is NeverSecret, safe to read
    if cdInfo.isOnGCD ~= nil then return true end
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

    -- Check Blizzard match
    local bridge = RA:GetModule("AssistedCombatBridge")
    if bridge then
        local rec = bridge:GetCurrentRecommendation()
        if rec and rec.spellID then
            if rec.spellID == spellID then
                sessionStats.blizzardMatches = sessionStats.blizzardMatches + 1
            else
                local ok1, info1 = pcall(C_Spell.GetSpellInfo, spellID)
                if ok1 and info1 and info1.name and info1.name == rec.name then
                    sessionStats.blizzardMatches = sessionStats.blizzardMatches + 1
                end
            end
        end
    end

    -- Check SmartQueue match
    local smartQ = RA:GetModule("SmartQueueManager")
    if smartQ then
        local qData = smartQ:GetFinalQueue()
        if qData and qData.main and qData.main.spellID == spellID then
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

        -- Same lazy match check for phase stats
        if bridge then
            local rec = bridge:GetCurrentRecommendation()
            if rec and rec.spellID == spellID then
                pStats.blizzMatches = pStats.blizzMatches + 1
            end
        end
        if smartQ then
            local qData = smartQ:GetFinalQueue()
            if qData and qData.main and qData.main.spellID == spellID then
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
        totalCasts = sessionStats.totalCasts,
        blizzardMatches = sessionStats.blizzardMatches,
        blizzardAccuracy = bPct,
        smartMatches = sessionStats.smartMatches,
        smartAccuracy = sPct,
        perPhase = sessionStats.perPhase
    }
end

---Get historical trend.
---获取历史趋势。
---@return table[]
function AccuracyTracker:GetHistoricalTrend()
    if RA.db and RA.db.profile.accuracyHistory then
        return RA.db.profile.accuracyHistory
    end
    return {}
end

---Reset session counters.
---重置会话计数。
function AccuracyTracker:Reset()
    sessionStats = {
        totalCasts = 0,
        blizzardMatches = 0,
        smartMatches = 0,
        perPhase = {}
    }
end

---Save session summary to SavedVariables.
---保存会话总结。
function AccuracyTracker:SaveSession()
    if not sessionActive then return end
    sessionActive = false

    local combatDuration = GetTime() - sessionStartTime
    if combatDuration < 5 or sessionStats.totalCasts == 0 then return end

    local stats = self:GetSessionStats()
    local specID = 0
    local specDet = RA:GetModule("SpecDetector")
    if specDet then specID = specDet:GetSpecID() or 0 end

    local record = {
        date = time(),
        specID = specID,
        duration = combatDuration,
        casts = stats.totalCasts,
        blizzardAccuracy = stats.blizzardAccuracy,
        smartAccuracy = stats.smartAccuracy
    }

    if RA.db then
        RA.db.profile.accuracyHistory = RA.db.profile.accuracyHistory or {}
        local history = RA.db.profile.accuracyHistory
        table.insert(history, 1, record)
        while #history > MAX_HISTORY do
            table.remove(history)
        end
    end

    local stars, verb = GetRatingDetails(stats.smartAccuracy)
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
            sessionActive = true
            sessionStartTime = GetTime()
        end)
        eh:Subscribe("PLAYER_REGEN_ENABLED", "AccuracyTracker", function()
            self:SaveSession()
        end)
    end

    if eh then
        eh:Subscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "AccuracyTracker", OnSpellCastSucceeded)
    end

    -- Slash command registration
    SLASH_RA_ACCURACY1 = "/ra accuracy"
    SlashCmdList["RA_ACCURACY"] = function()
        RA:Print("--- RotaAssist Accuracy History ---")
        local hist = self:GetHistoricalTrend()
        if #hist == 0 then
            RA:Print("No records yet.")
        else
            for i = 1, math.min(10, #hist) do
                local r = hist[i]
                local s, v = GetRatingDetails(r.smartAccuracy)
                RA:Print(string.format("#%d [%s]: Smart %.1f%% / Blizz %.1f%% %s",
                    i, date("%m/%d %H:%M", r.date), r.smartAccuracy, r.blizzardAccuracy, s))
            end
        end
        RA:Print("-----------------------------------")
    end
end

function AccuracyTracker:OnDisable()
    local eh = RA:GetModule("EventHandler")
    if eh then eh:Unsubscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "AccuracyTracker") end
    sessionActive = false
    SLASH_RA_ACCURACY1 = nil
    SlashCmdList["RA_ACCURACY"] = nil
end
