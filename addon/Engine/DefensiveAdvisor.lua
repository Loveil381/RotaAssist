------------------------------------------------------------------------
-- RotaAssist - Defensive Advisor
-- Monitors player HP% and recommends defensive abilities when low.
-- Uses UnitHealth/UnitHealthMax which are safe during combat in 12.0.
-- プレイヤーHP監視と防御スキル推薦。
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local DefensiveAdvisor = {}
RA:RegisterModule("DefensiveAdvisor", DefensiveAdvisor)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

--- Per-spec defensive config from SpecEnhancements
---@type table[]|nil   array of { spellID, hpThreshold, name, texture }
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

--- Last known HP ratio (avoid firing duplicate alerts)
---@type number
local lastHpPct = 1.0

------------------------------------------------------------------------
-- HP Check Logic
------------------------------------------------------------------------

local function checkHealth()
    -- UnitHealth / UnitHealthMax are safe in combat for "player"
    local hp    = UnitHealth("player") or 0
    local hpMax = UnitHealthMax("player") or 1
    if hpMax <= 0 then hpMax = 1 end

    local hpPct = hp / hpMax
    lastHpPct = hpPct

    if not defensives then return end

    local eh = RA:GetModule("EventHandler")

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

                -- Store for GetActiveRecommendation()
                lastActiveAlert = {
                    spellID = def.spellID,
                    name    = def.name,
                    urgency = 1.0 - hpPct,  -- lower HP = higher urgency
                    texture = def.texture or 134400,
                }

                if eh and eh.Fire then
                    eh:Fire("ROTAASSIST_DEFENSIVE_ALERT", def.spellID, hpPct, def.hpThreshold)
                end
            end
            return  -- only recommend the highest priority defensive
        end
    end

    -- HP recovered above all thresholds — reset alert state
    lastAlertSpellID = nil
    lastActiveAlert = nil
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
        -- Enrich with texture/name
        defensives = {}
        for _, def in ipairs(enhData.defensives) do
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
            defensives[#defensives + 1] = entry
        end
        -- Sort by threshold descending (check highest threshold first)
        table.sort(defensives, function(a, b) return a.hpThreshold > b.hpThreshold end)

        isTracking = true
        updateFrame:SetScript("OnUpdate", onUpdate)
        RA:PrintDebug(string.format("DefensiveAdvisor: %d defensives for specID %d",
            #defensives, specID))
    else
        updateFrame:SetScript("OnUpdate", nil)
    end
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get the current HP percentage.
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
