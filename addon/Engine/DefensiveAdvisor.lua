------------------------------------------------------------------------
-- RotaAssist - Defensive Advisor
-- Monitors player HP% and recommends defensive abilities when low.
-- WOW 12.0 SECRET VALUE SAFE: Uses C_CurveUtil curves for in-combat
-- threshold detection. Out of combat uses normal arithmetic.
-- プレイヤーHP監視と防御スキル推薦。12.0シークレット値対応済み。
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local DefensiveAdvisor = {}
RA:RegisterModule("DefensiveAdvisor", DefensiveAdvisor)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

--- Per-spec defensive config from SpecEnhancements
---@type table[]|nil   array of { spellID, hpThreshold, name, texture, thresholdCurve, probeFrame }
local defensives = nil

--- OnUpdate throttle (HP changes continuously; 4 Hz is sufficient)
local UPDATE_INTERVAL = 0.25
local elapsed = 0
local updateFrame = nil
local isTracking = false

--- Last alert spellID (prevent spam — only alert once per defensive per event)
---@type number|nil
local lastAlertSpellID = nil

--- Last active alert data for GetActiveRecommendation()
---@type table|nil  { spellID, name, urgency, texture }
local lastActiveAlert = nil

--- Last known HP ratio (cached from out-of-combat reads)
---@type number
local lastHpPct = 1.0

--- Threshold curve cache: threshold(0-1) -> curve object
local THRESHOLD_CURVES = {}

--- Probe frames for in-combat secret value detection: spellID -> frame
local probeFrames = {}

------------------------------------------------------------------------
-- WOW 12.0 SECRET VALUE SAFE: Curve-Based Threshold Detection
------------------------------------------------------------------------

--- Creates a step curve: returns alpha=1 when HP% is below threshold, alpha=0 above.
--- @param threshold number HP threshold as 0-1 (e.g. 0.35 for 35%)
--- @return table curve C_CurveUtil color curve
local function CreateThresholdCurve(threshold)
    local curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Step)
    -- HP 0%: alpha = 1 (alert visible, HP is below threshold)
    curve:AddPoint(0, CreateColor(1, 0, 0, 1))
    -- HP at threshold%: alpha = 0 (alert hidden, HP is above threshold)
    curve:AddPoint(threshold * 100, CreateColor(0, 1, 0, 0))
    return curve
end

--- Get or create a cached threshold curve for a given HP threshold.
--- @param threshold number 0-1
--- @return table curve
local function GetOrCreateThresholdCurve(threshold)
    if not THRESHOLD_CURVES[threshold] then
        THRESHOLD_CURVES[threshold] = CreateThresholdCurve(threshold)
    end
    return THRESHOLD_CURVES[threshold]
end

--- Create a tiny hidden probe frame for driving visual alerts with secret values.
--- @param parent table Parent frame
--- @param index number Index for naming
--- @return table probeFrame
local function CreateProbeFrame(parent, index)
    local f = CreateFrame("Frame", "RA_DefProbe" .. index, parent)
    f:SetSize(1, 1)
    f:SetPoint("CENTER", UIParent, "CENTER", -10000, -10000)
    f:Show()
    return f
end

------------------------------------------------------------------------
-- HP Check Logic (issecretvalue-based: arithmetic when readable, curves when secret)
------------------------------------------------------------------------

local function checkHealth()
    if not defensives then return end
    local eh = RA:GetModule("EventHandler")

    -- WOW 12.0 SECRET VALUE SAFE
    local hpPct = RA:GetPlayerHealthPercentSafe()

    if hpPct then
        -- 可以读取：完整阈值判断
        lastHpPct = hpPct

        for _, def in ipairs(defensives) do
            if hpPct <= def.hpThreshold then
                local remaining, ready = RA:GetSpellCooldownSafe(def.spellID)
                -- remaining==nil 表示 secret，假设可用（宁可多提醒）
                if remaining == nil or ready then
                    if lastAlertSpellID ~= def.spellID then
                        lastAlertSpellID = def.spellID
                        lastActiveAlert = {
                            spellID = def.spellID,
                            name    = def.name,
                            urgency = 1.0 - hpPct,
                            texture = def.texture or 134400,
                        }
                        if eh and eh.Fire then
                            eh:Fire("ROTAASSIST_DEFENSIVE_ALERT", def.spellID, hpPct, def.hpThreshold)
                        end
                    end
                end
                return
            end
        end
        lastAlertSpellID = nil
        lastActiveAlert = nil
    else
        -- HP 不可读（secret）：用 curve 驱动视觉层
        for _, def in ipairs(defensives) do
            if def.thresholdCurve and def.probeFrame then
                local ok, color = pcall(UnitHealthPercent, "player", true, def.thresholdCurve)
                if ok and color then
                    local ok2, r, g, b, a = pcall(color.GetRGBA, color)
                    if ok2 and a then
                        def.probeFrame:SetAlpha(a)
                    end
                end
            end
        end
        -- HP secret: check probe frame alpha to populate lastActiveAlert
        -- 针对 HP secret 模式：检查探针 Frame 通道透明度来更新推荐状态
        local foundDefAlert = false
        for _, def in ipairs(defensives) do
            if def.probeFrame then
                local okAlpha, isBelow = pcall(function()
                    return def.probeFrame:GetAlpha() > 0.5
                end)
                if okAlpha and isBelow then
                    lastActiveAlert = {
                        spellID = def.spellID,
                        name    = def.name,
                        urgency = 0.8,
                        texture = def.texture or 134400,
                    }
                    foundDefAlert = true
                    break
                end
            end
        end
        if not foundDefAlert then
            lastActiveAlert = nil
        end

        if eh and eh.Fire then
            eh:Fire("ROTAASSIST_DEFENSIVE_UPDATE", probeFrames, defensives)
        end
    end
end

local function onUpdate(_, dt)
    if not isTracking then return end
    elapsed = elapsed + dt
    if elapsed < UPDATE_INTERVAL then return end
    elapsed = 0
    checkHealth()
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function DefensiveAdvisor:OnInitialize()
    updateFrame = CreateFrame("Frame", "RotaAssist_DefensiveAdvisorFrame")
end

function DefensiveAdvisor:OnEnable()
    if not updateFrame then return end

    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ROTAASSIST_SPEC_CHANGED", "DefensiveAdvisor", function(_, specInfo)
            self:LoadForSpec(specInfo and specInfo.specID)
        end)

        -- Reset alert state when leaving combat
        eh:Subscribe("PLAYER_REGEN_ENABLED", "DefensiveAdvisor", function()
            -- WOW 12.0 SECRET VALUE SAFE: may remain secret in M+/PvP
            local pct = RA:GetPlayerHealthPercentSafe()
            if pct then lastHpPct = pct end
            lastAlertSpellID = nil
            lastActiveAlert = nil
        end)
    end

    -- Try loading immediately
    local sd = RA:GetModule("SpecDetector")
    if sd then
        local spec = sd:GetCurrentSpec()
        if spec then self:LoadForSpec(spec.specID) end
    end
end

---Load defensive config for a given specID.
---@param specID number|nil
function DefensiveAdvisor:LoadForSpec(specID)
    defensives = nil
    isTracking = false
    lastAlertSpellID = nil
    lastActiveAlert = nil

    -- Clean up old probe frames from previous spec
    for sid, f in pairs(probeFrames) do
        f:Hide()
        f:SetParent(nil)
    end
    wipe(probeFrames)
    wipe(THRESHOLD_CURVES)

    if not specID or not RA.SpecEnhancements then return end

    local enhData = RA.SpecEnhancements[specID]
    if enhData and enhData.defensives and #enhData.defensives > 0 then
        -- Enrich with texture/name and create threshold curves
        defensives = {}
        for i, def in ipairs(enhData.defensives) do
            local entry = {
                spellID     = def.spellID,
                hpThreshold = def.hpThreshold or 0.35,
            }
            local ok, info = pcall(C_Spell.GetSpellInfo, def.spellID)
            if ok and info then
                entry.name    = info.name
                entry.texture = info.iconID
            else
                entry.name    = "Spell#" .. def.spellID
                entry.texture = 134400
            end

            -- WOW 12.0 SECRET VALUE SAFE: Pre-build curve for in-combat use
            entry.thresholdCurve = GetOrCreateThresholdCurve(entry.hpThreshold)
            entry.probeFrame = CreateProbeFrame(updateFrame, i)
            probeFrames[entry.spellID] = entry.probeFrame

            defensives[#defensives + 1] = entry
        end
        -- Sort by threshold descending (check highest threshold first)
        table.sort(defensives, function(a, b) return a.hpThreshold > b.hpThreshold end)

        isTracking = true
        updateFrame:SetScript("OnUpdate", onUpdate)
        RA:PrintDebug(string.format("DefensiveAdvisor: %d defensives for specID %d (12.0 curve-safe)",
            #defensives, specID))
    else
        updateFrame:SetScript("OnUpdate", nil)
    end
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get the current HP percentage. Attempts live read, falls back to cache.
--- WOW 12.0 SECRET VALUE SAFE: Returns last known non-secret value.
---@return number hpPct 0.0–1.0
function DefensiveAdvisor:GetHealthPercent()
    local pct = RA:GetPlayerHealthPercentSafe()
    if pct then lastHpPct = pct end
    return lastHpPct
end

---Get the list of configured defensives for the current spec.
---@return table[]|nil
function DefensiveAdvisor:GetDefensives()
    return defensives
end

---Get the active defensive recommendation (if any).
---Returns the last alert data when HP is below a threshold and a defensive is ready.
---@return table|nil recommendation { spellID, name, urgency, texture }
function DefensiveAdvisor:GetActiveRecommendation()
    return lastActiveAlert
end
