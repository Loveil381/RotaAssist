------------------------------------------------------------------------
-- RotaAssist - Recommendation Manager
-- ⚠ DEPRECATED (Phase 0): This module has been superseded by
-- SmartQueueManager, which provides a unified fusion layer combining
-- Blizzard, APL, AI Inference, Cooldowns, and Defensives.
-- This file is kept for reference only and is commented out in the TOC.
------------------------------------------------------------------------
-- Merges 3 data sources into the final display list:
--   Slot 1: C_AssistedCombat (Bridge) — always position 1, confidence 1.0
--   Slot 2-3: APLEngine:PredictNext() — look-ahead prediction
--   Sidebar: CooldownOverlay — big CD readiness states
--   Alert:   DefensiveAdvisor — low-HP defensive recommendations
-- Fires "ROTAASSIST_RECOMMENDATION_UPDATED" for the UI.
-- 推薦マネージャー: 3つのデータソースを統合して最終推薦リストを生成する。
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local RecommendationManager = {}
RA:RegisterModule("RecommendationManager", RecommendationManager)

------------------------------------------------------------------------
-- Source & Confidence Constants
------------------------------------------------------------------------

local SOURCE = {
    BLIZZARD       = "blizzard",       -- C_AssistedCombat / AssistCapture fallback
    APL_PREDICT    = "apl_predict",    -- APL simulation look-ahead
    COOLDOWN_READY = "cooldown_ready", -- major CD ready reminder
    DEFENSIVE      = "defensive",      -- low-HP defensive recommendation
}

local CONFIDENCE = {
    [SOURCE.BLIZZARD]       = 1.0,
    [SOURCE.APL_PREDICT]    = 0.7,  -- overridden per-step by PredictNext
    [SOURCE.COOLDOWN_READY] = 0.4,
    [SOURCE.DEFENSIVE]      = 0.95, -- defensive is urgent
}

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

---@class RecommendationEntry
---@field spellID    number
---@field spellName  string
---@field icon       number   Texture ID
---@field keybind    string|nil
---@field source     string
---@field confidence number
---@field reason     string|nil

--- Cached recommendations (invalidated on update events)
---@type RecommendationEntry[]|nil
local cachedRecommendations = nil

--- Cached sidebar (big CDs)
---@type table[]|nil
local cachedSidebar = nil

--- Current defensive alert entry
---@type RecommendationEntry|nil
local currentAlert = nil

--- Current resource state
local currentResource = { current = 0, max = 100, percentage = 0, powerType = nil }

------------------------------------------------------------------------
-- Keybind Resolution
------------------------------------------------------------------------

---@param spellID number
---@return string|nil
local function findKeybindForSpell(spellID)
    for slot = 1, 120 do
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" and id == spellID then
            local key = GetBindingKey("ACTIONBUTTON" .. slot)
            if not key then
                if slot > 72 then
                    key = GetBindingKey("MULTIACTIONBAR3BUTTON" .. (slot - 72))
                elseif slot > 60 then
                    key = GetBindingKey("MULTIACTIONBAR4BUTTON" .. (slot - 60))
                elseif slot > 48 then
                    key = GetBindingKey("MULTIACTIONBAR2BUTTON" .. (slot - 48))
                elseif slot > 36 then
                    key = GetBindingKey("MULTIACTIONBAR1BUTTON" .. (slot - 36))
                end
            end
            if key then return key end
        end
    end
    return nil
end

------------------------------------------------------------------------
-- Spell Metadata
------------------------------------------------------------------------

---@param spellID number
---@return string name, number icon
local function getSpellMeta(spellID)
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    if ok and info then
        return info.name or ("Spell#" .. spellID), info.iconID or 134400
    end
    return "Spell#" .. spellID, 134400
end

---@param spellID number
---@param source  string
---@param reason  string|nil
---@return RecommendationEntry
local function makeEntry(spellID, source, reason)
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

------------------------------------------------------------------------
-- Assembly Logic
-- 推薦リスト組立ロジック
------------------------------------------------------------------------

---Build the observable state for APLEngine prediction.
---@return table limitedState
local function buildLimitedState()
    local state = {
        resource    = 0,
        cooldowns   = {},
        inMeta      = false,
        targetCount = 1,
    }

    currentResource.powerType = nil

    -- Read player resource (combat-safe)
    local enhData = nil
    local sd = RA:GetModule("SpecDetector")
    if sd then
        local spec = sd:GetCurrentSpec()
        if spec and RA.SpecEnhancements then
            enhData = RA.SpecEnhancements[spec.specID]
        end
    end

    if enhData and enhData.resource then
        local powerType = enhData.resource.type
        currentResource.powerType = powerType
        if powerType then
            local ok, power = pcall(UnitPower, "player", powerType)
            if ok and power then 
                state.resource = power 
                currentResource.current = power
            end
            
            local ok2, maxPower = pcall(UnitPowerMax, "player", powerType)
            if ok2 and maxPower then
                currentResource.max = maxPower
                currentResource.percentage = maxPower > 0 and (currentResource.current / maxPower) or 0
            end
        end
    end

    -- Read cooldown states from CooldownTracker
    local cdTracker = RA:GetModule("CooldownTracker")
    if cdTracker then
        local allCDs = cdTracker:GetAllCooldowns()
        for spellID, cdState in pairs(allCDs) do
            state.cooldowns[spellID] = cdState.remaining or 0
        end
    end

    -- Meta state from APLEngine
    local aplEngine = RA:GetModule("APLEngine")
    if aplEngine then
        state.inMeta = aplEngine:IsMetaActive()
    end

    -- Target mode from display settings
    if RA.db and RA.db.profile.display and RA.db.profile.display.mode == "M+" then
        state.targetCount = 3
    end

    return state
end

---Assemble the final recommendation list.
---@param count number  Number of main icons (default 3)
---@return RecommendationEntry[] main, table[] sidebar
local function assembleRecommendations(count)
    count = count or 3
    local result    = {}
    local sidebar   = {}
    local usedSpells = {}

    -- ─── Source 1: C_AssistedCombat (Bridge) — always slot 1 ───
    local blizzardSpellID = nil
    local bridge = RA:GetModule("AssistedCombatBridge")
    if bridge then
        local rec = bridge:GetCurrentRecommendation()
        if rec and rec.spellID then
            blizzardSpellID = rec.spellID
        end
    end

    -- Fallback: AssistCapture glow hooks (if Bridge is unavailable)
    if not blizzardSpellID then
        local ac = RA:GetModule("AssistCapture")
        if ac then
            blizzardSpellID = ac:GetCurrentRecommendation()
        end
    end

    if blizzardSpellID and not usedSpells[blizzardSpellID] then
        result[#result + 1] = makeEntry(blizzardSpellID, SOURCE.BLIZZARD, "Blizzard recommendation")
        usedSpells[blizzardSpellID] = true
    end

    -- ─── Source 2: APL Prediction (steps 2-3) ───
    local aplEngine = RA:GetModule("APLEngine")
    local limitedState = buildLimitedState() -- also populates currentResource

    if aplEngine and aplEngine:HasAPL() and blizzardSpellID then
        local predictions  = aplEngine:PredictNext(blizzardSpellID, limitedState, count - 1)

        for _, pred in ipairs(predictions) do
            if #result >= count then break end
            if not usedSpells[pred.spellID] then
                local entry = makeEntry(pred.spellID, SOURCE.APL_PREDICT, pred.note)
                entry.confidence = pred.confidence or CONFIDENCE[SOURCE.APL_PREDICT]
                result[#result + 1] = entry
                usedSpells[pred.spellID] = true
            end
        end
    end

    -- ─── Source 3: Cooldown Ready fallback (fill remaining slots) ───
    if #result < count then
        local cdTracker = RA:GetModule("CooldownTracker")
        if cdTracker then
            local ready = cdTracker:GetReadySpells()
            for _, spell in ipairs(ready) do
                if #result >= count then break end
                if not usedSpells[spell.spellID] then
                    result[#result + 1] = makeEntry(spell.spellID, SOURCE.COOLDOWN_READY, "CD ready")
                    usedSpells[spell.spellID] = true
                end
            end
        end
    end

    -- ─── Sidebar: Major Cooldown States ───
    local cdOverlay = RA:GetModule("CooldownOverlay")
    if cdOverlay then
        local states = cdOverlay:GetCooldownStates()
        -- Sort them predictably (by spellID or remaining time)
        local sortedCDs = {}
        for spellID, state in pairs(states) do
            sortedCDs[#sortedCDs + 1] = { spellID = spellID, state = state }
        end
        table.sort(sortedCDs, function(a, b) return a.spellID < b.spellID end)

        for _, item in ipairs(sortedCDs) do
            local spellID = item.spellID
            local state = item.state
            
            -- Prepare duration / startTime if available
            local cdInfo
            local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
            if ok and info then cdInfo = info end
            
            sidebar[#sidebar + 1] = {
                spellID   = spellID,
                name      = state.name,
                texture   = state.texture,
                remaining = state.remaining,
                duration  = cdInfo and cdInfo.duration or 60,
                startTime = cdInfo and cdInfo.startTime or GetTime(),
                ready     = state.ready,
                alerting  = (state.remaining > 0 and state.remaining <= 5)
            }
        end
    end

    return result, sidebar
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function RecommendationManager:OnInitialize() end

function RecommendationManager:OnEnable()
    local eh = RA:GetModule("EventHandler")
    if not eh then return end

    -- Invalidate cache on any relevant event
    local function invalidate()
        cachedRecommendations = nil
        cachedSidebar         = nil
    end

    eh:Subscribe("ROTAASSIST_BRIDGE_UPDATED",     "RecommendationManager", invalidate)
    eh:Subscribe("ROTAASSIST_ASSIST_UPDATED",     "RecommendationManager", invalidate)
    eh:Subscribe("ROTAASSIST_COOLDOWNS_UPDATED",  "RecommendationManager", invalidate)
    eh:Subscribe("ROTAASSIST_SPEC_CHANGED",       "RecommendationManager", invalidate)

    -- Defensive alert → store for UI
    eh:Subscribe("ROTAASSIST_DEFENSIVE_ALERT", "RecommendationManager", function(_, spellID, hpPct)
        currentAlert = makeEntry(spellID, SOURCE.DEFENSIVE,
            string.format("HP %.0f%% — use defensive!", hpPct * 100))
        currentAlert.alerting = true
        -- Also fire recommendation update so UI refreshes
        eh:Fire("ROTAASSIST_RECOMMENDATION_UPDATED")
    end)

    -- Fire recommendation update whenever cache is invalidated
    eh:Subscribe("ROTAASSIST_BRIDGE_UPDATED", "RecommendationManager_Fire", function()
        eh:Fire("ROTAASSIST_RECOMMENDATION_UPDATED")
    end)
    eh:Subscribe("ROTAASSIST_ASSIST_UPDATED", "RecommendationManager_Fire2", function()
        eh:Fire("ROTAASSIST_RECOMMENDATION_UPDATED")
    end)
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get the consolidated display data for the new T-shaped UI.
---@return table
function RecommendationManager:GetDisplayData()
    local recs = self:GetRecommendations(3)
    local sidebar = self:GetSidebar()
    
    local data = {
        main = nil,
        predictions = {},
        cooldowns = sidebar,
        defensive = currentAlert,
        resource = {
            current = currentResource.current,
            max = currentResource.max,
            percentage = currentResource.percentage,
            powerType = currentResource.powerType
        },
        aiContext = nil
    }
    
    local aiModule = RA:GetModule("AIInference")
    if aiModule and aiModule.GetContext then
        local ctx = aiModule:GetContext()
        data.aiContext = {
            phase = ctx.inferred.combatPhase,
            phaseConfidence = ctx.inferred.phaseConfidence,
            targetCount = ctx.targetCount,
            tip = ctx.inferred.tip,
            inferredResource = ctx.inferred.resourceState
        }
    end
    
    if #recs > 0 then
        -- Map confidence 0.0-1.0 to stars: 1-3
        local confStars = 3
        if recs[1].confidence < 0.6 then confStars = 1
        elseif recs[1].confidence < 0.9 then confStars = 2 end
        
        data.main = {
            spellID = recs[1].spellID,
            texture = recs[1].icon,
            name = recs[1].spellName,
            keybind = recs[1].keybind,
            confidence = confStars
        }
        
        for i = 2, #recs do
            local pConf = 3
            if recs[i].confidence < 0.6 then pConf = 1
            elseif recs[i].confidence < 0.9 then pConf = 2 end
            data.predictions[i - 1] = {
                spellID = recs[i].spellID,
                texture = recs[i].icon,
                confidence = pConf
            }
        end
    end
    
    return data
end

---Get the current main recommendation list.
---@param count number|nil (default 3)
---@return RecommendationEntry[]
function RecommendationManager:GetRecommendations(count)
    count = count or 3
    if cachedRecommendations and #cachedRecommendations >= count then
        if #cachedRecommendations == count then
            return cachedRecommendations
        end
        local subset = {}
        for i = 1, count do subset[i] = cachedRecommendations[i] end
        return subset
    end
    cachedRecommendations, cachedSidebar = assembleRecommendations(count)
    return cachedRecommendations
end

---Alias for MainDisplay compatibility (was Predictor:GetPredictions)
---@param count number|nil
---@return RecommendationEntry[]
function RecommendationManager:GetPredictions(count)
    return self:GetRecommendations(count)
end

---Get sidebar cooldown states.
---@return table[]
function RecommendationManager:GetSidebar()
    if not cachedSidebar then
        cachedRecommendations, cachedSidebar = assembleRecommendations(3)
    end
    return cachedSidebar or {}
end

---Get current defensive alert (if any).
---@return RecommendationEntry|nil
function RecommendationManager:GetDefensiveAlert()
    return currentAlert
end

---Clear defensive alert (called after UI shows it).
function RecommendationManager:ClearAlert()
    currentAlert = nil
end

---Force refresh (bypass cache).
---@param count number|nil
---@return RecommendationEntry[]
function RecommendationManager:Refresh(count)
    cachedRecommendations = nil
    cachedSidebar         = nil
    return self:GetRecommendations(count)
end

---Get source constants.
---@return table
function RecommendationManager:GetSources()
    return SOURCE
end
