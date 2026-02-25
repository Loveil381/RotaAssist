------------------------------------------------------------------------
-- RotaAssist - Predictor
-- Integrates AssistCapture + CooldownTracker + APLEngine to produce
-- the final display list of recommended spell icons.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local Predictor = {}
RA:RegisterModule("Predictor", Predictor)

------------------------------------------------------------------------
-- Source & Confidence Constants
------------------------------------------------------------------------

--- Sources for each prediction entry
local SOURCE = {
    BLIZZARD       = "blizzard",       -- direct from Blizzard Assisted Highlights
    APL_PREDICT    = "apl_predict",    -- from APL engine simulation
    COOLDOWN_READY = "cooldown_ready", -- fallback: spell is off cooldown
}

--- Confidence levels per source
local CONFIDENCE = {
    [SOURCE.BLIZZARD]       = 1.0,  -- highest: Blizzard is recommending it
    [SOURCE.APL_PREDICT]    = 0.7,  -- APL simulation
    [SOURCE.COOLDOWN_READY] = 0.5,  -- just a ready cooldown
}

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

---@class PredictionEntry
---@field spellID number
---@field spellName string
---@field icon number Texture ID
---@field keybind string|nil Bound key text (e.g. "1", "Shift-Q")
---@field source string "blizzard" | "apl_predict" | "cooldown_ready"
---@field confidence number 0.0 – 1.0
---@field reason string|nil Why this is recommended

--- Cached predictions (invalidated on any update event)
---@type PredictionEntry[]|nil
local cachedPredictions = nil

------------------------------------------------------------------------
-- Keybind Resolution
------------------------------------------------------------------------

---Get the keybind text for an action bar button whose spell matches.
---@param spellID number
---@return string|nil keybind
local function findKeybindForSpell(spellID)
    -- Scan the standard action bars for a matching spell
    for slot = 1, 120 do
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" and id == spellID then
            local key = GetBindingKey("ACTIONBUTTON" .. slot)
            if not key then
                -- Check multi-bar bindings
                if slot > 72 then
                    key = GetBindingKey("MULTIACTIONBAR3BUTTON" .. (slot - 72))
                elseif slot > 60 then
                    key = GetBindingKey("MULTIACTIONBAR4BUTTON" .. (slot - 60))
                elseif slot > 48 then
                    key = GetBindingKey("MULTIACTIONBAR2BUTTON" .. (slot - 48))
                elseif slot > 36 then
                    key = GetBindingKey("MULTIACTIONBAR1BUTTON" .. (slot - 36))
                elseif slot > 24 then
                    key = GetBindingKey("ACTIONBUTTON" .. (slot - 24))
                elseif slot > 12 then
                    key = GetBindingKey("ACTIONBUTTON" .. (slot - 12))
                end
            end
            if key then return key end
        end
    end
    return nil
end

------------------------------------------------------------------------
-- Spell Metadata Helper
------------------------------------------------------------------------

---Get spell name and icon for a spellID.
---@param spellID number
---@return string name
---@return number icon Texture ID
local function getSpellMeta(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    if info then
        return info.name, info.iconID
    end
    return "Spell#" .. spellID, 134400  -- 134400 = question mark
end

------------------------------------------------------------------------
-- Prediction Assembly
------------------------------------------------------------------------

---Build a PredictionEntry table.
---@param spellID number
---@param source string
---@param reason string|nil
---@return PredictionEntry
local function makePrediction(spellID, source, reason)
    local name, icon = getSpellMeta(spellID)
    return {
        spellID    = spellID,
        spellName  = name,
        icon       = icon,
        keybind    = findKeybindForSpell(spellID),
        source     = source,
        confidence = CONFIDENCE[source] or 0.3,
        reason     = reason,
    }
end

---Generate the final prediction list.
---@param count number Number of icons to return (default 3)
---@return PredictionEntry[]
local function assemblePredictions(count)
    count = count or 3
    local result = {}
    local usedSpells = {}

    -- Step 1: Blizzard Assisted Highlights (highest priority)
    local blizzardSpellID = nil
    local assistCapture = RA:GetModule("AssistCapture")
    if assistCapture then
        blizzardSpellID = assistCapture:GetCurrentRecommendation()
        if blizzardSpellID and not usedSpells[blizzardSpellID] then
            result[#result + 1] = makePrediction(
                blizzardSpellID,
                SOURCE.BLIZZARD,
                "Blizzard priority"
            )
            usedSpells[blizzardSpellID] = true
        end
    end

    -- Get cool down states
    local cdTracker = RA:GetModule("CooldownTracker")
    local cooldownStates = cdTracker and cdTracker:GetAllCooldowns() or {}

    -- Step 2: APL Engine predictions
    local aplEngine = RA:GetModule("APLEngine")
    if aplEngine and aplEngine:HasAPL() then
        -- Default target count 1 since we don't have aura/environment reading for exact enemies yet
        local targetCount = 1
        
        -- Call Phase 2 Eval Loop
        local aplPredictions = aplEngine:Evaluate(cooldownStates, blizzardSpellID, targetCount)
        
        for _, pred in ipairs(aplPredictions) do
            if #result >= count then break end
            
            if not usedSpells[pred.spellID] then
                local entry = makePrediction(
                    pred.spellID,
                    pred.source or SOURCE.APL_PREDICT,
                    pred.note or pred.reason
                )
                entry.confidence = pred.confidence or CONFIDENCE[SOURCE.APL_PREDICT]
                result[#result + 1] = entry
                usedSpells[pred.spellID] = true
            end
        end
    end

    -- Step 3: Cooldown-ready fallback (fill any remaining slots)
    if cdTracker and #result < count then
        local readySpells = cdTracker:GetReadySpells()
        for _, spell in ipairs(readySpells) do
            if #result >= count then break end
            if not usedSpells[spell.spellID] then
                result[#result + 1] = makePrediction(
                    spell.spellID,
                    SOURCE.COOLDOWN_READY,
                    "Cooldown ready"
                )
                usedSpells[spell.spellID] = true
            end
        end
    end

    return result
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function Predictor:OnInitialize()
    -- Nothing to do here
end

function Predictor:OnEnable()
    -- Subscribe to all relevant update events to invalidate cache
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ROTAASSIST_ASSIST_UPDATED", "Predictor", function()
            cachedPredictions = nil
        end)

        eh:Subscribe("ROTAASSIST_COOLDOWNS_UPDATED", "Predictor", function()
            cachedPredictions = nil
        end)

        eh:Subscribe("ROTAASSIST_SPEC_CHANGED", "Predictor", function()
            cachedPredictions = nil
        end)
    end
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get the current prediction list.
---Results are cached until an update event invalidates them.
---@param count number|nil Number of icons (default 3)
---@return PredictionEntry[] predictions
function Predictor:GetPredictions(count)
    count = count or 3
    if cachedPredictions and #cachedPredictions >= count then
        -- Return first 'count' entries from cache
        if #cachedPredictions == count then
            return cachedPredictions
        end
        local subset = {}
        for i = 1, count do
            subset[i] = cachedPredictions[i]
        end
        return subset
    end

    cachedPredictions = assemblePredictions(count)
    return cachedPredictions
end

---Force a fresh prediction (bypass cache).
---@param count number|nil
---@return PredictionEntry[]
function Predictor:Refresh(count)
    cachedPredictions = nil
    return self:GetPredictions(count)
end

---Get the source constants for external use.
---@return table SOURCE { BLIZZARD, APL_PREDICT, COOLDOWN_READY }
function Predictor:GetSources()
    return SOURCE
end

---Get the confidence levels for external use.
---@return table CONFIDENCE { [source] = number }
function Predictor:GetConfidenceLevels()
    return CONFIDENCE
end
