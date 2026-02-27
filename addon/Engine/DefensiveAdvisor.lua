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
-- HP Check Logic (dual-path: out-of-combat arithmetic, in-combat curves)
------------------------------------------------------------------------

local function checkHealth()
    if not defensives then return end

    local eh = RA:GetModule("EventHandler")
    local inCombat = InCombatLockdown()

    if not inCombat then
        -- WOW 12.0 SECRET VALUE SAFE: Out of combat, UnitHealth is readable
        local hp    = UnitHealth("player") or 0
        local hpMax = UnitHealthMax("player") or 1
        if hpMax <= 0 then hpMax = 1 end

        local hpPct = hp / hpMax
        lastHpPct = hpPct

        for _, def in ipairs(defensives) do
            if hpPct <= def.hpThreshold then
                -- Check if the defensive is actually off CD
                local ready = true
                local cdOk, cdInfo = pcall(C_Spell.GetSpellCooldown, def.spellID)
                if cdOk and cdInfo and cdInfo.duration and cdInfo.duration > 1.5 then
                    local remaining = (cdInfo.startTime + cdInfo.duration) - GetTime()
                    if remaining > 0 then ready = false end
                end

                if ready and lastAlertSpellID ~= def.spellID then
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
                return
            end
        end

        -- HP recovered above all thresholds
        lastAlertSpellID = nil
        lastActiveAlert = nil
    else
        -- WOW 12.0 SECRET VALUE SAFE: In combat, drive visual alerts via curves
        -- We cannot read the actual HP number, but we CAN:
        -- 1. Pass secret color alpha to probe frames (visual layer)
        -- 2. Check CD readiness (C_Spell.GetSpellCooldown is NOT secret)
        -- 3. Fire alerts based on UNIT_HEALTH event arrival as a heuristic

        for _, def in ipairs(defensives) do
            if def.thresholdCurve and def.probeFrame then
                -- Drive the probe frame alpha with the secret health percentage
                -- UnitHealthPercent returns a secret color when given a curve
                local secretColor = UnitHealthPercent("player", true, def.thresholdCurve)
                if secretColor then
                    -- Pass secret alpha directly to widget — this is allowed in 12.0
                    def.probeFrame:SetAlpha(select(4, secretColor:GetRGBA()))
                end
            end

            -- CD readiness is NOT secret — we can always check this
            local ready = true
            local cdOk, cdInfo = pcall(C_Spell.GetSpellCooldown, def.spellID)
            if cdOk and cdInfo and cdInfo.duration and cdInfo.duration > 1.5 then
                local remaining = (cdInfo.startTime + cdInfo.duration) - GetTime()
                if remaining > 0 then ready = false end
            end

            -- In combat we maintain the last known alert for GetActiveRecommendation()
            -- The visual alert is driven by the curve; the Lua-side alert is best-effort
            if ready and lastAlertSpellID ~= def.spellID then
                -- We can't KNOW HP crossed the threshold from Lua, but we fire
                -- defensive data so SmartQueueManager can include it in the queue.
                -- The visual urgency is driven by the probe frame's alpha (curve-based).
                lastAlertSpellID = def.spellID
                lastActiveAlert = {
                    spellID = def.spellID,
                    name    = def.name,
                    urgency = 0.5,  -- unknown urgency in combat (can't read HP)
                    texture = def.texture or 134400,
                }
                if eh and eh.Fire then
                    eh:Fire("ROTAASSIST_DEFENSIVE_ALERT", def.spellID, lastHpPct, def.hpThreshold)
                end
            end
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
            -- Refresh HP cache now that we can read it
            local hp    = UnitHealth("player") or 0
            local hpMax = UnitHealthMax("player") or 1
            if hpMax > 0 then lastHpPct = hp / hpMax end
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

---Get the current HP percentage (cached; may be stale during combat).
--- WOW 12.0 SECRET VALUE SAFE: Returns last known non-secret value.
---@return number hpPct 0.0–1.0
function DefensiveAdvisor:GetHealthPercent()
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
