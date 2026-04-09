------------------------------------------------------------------------
-- RotaAssist - Assisted Combat Bridge
-- Wraps Blizzard's C_AssistedCombat API (WoW 11.1.7+ / 12.0 core).
-- Primary data source for combat rotation recommendations.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local Bridge = {}
RA:RegisterModule("AssistedCombatBridge", Bridge)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

--- Cached current recommendation { spellID, texture, name }
---@type table|nil
local cachedRec = nil

-- Cache the previous recommendation so AccuracyTracker can compare
-- against the spell that was shown before the cast succeeded.
---@type table|nil
local previousRec = nil

--- Callbacks registered for ASSISTED_COMBAT_ACTION_SPELL_CAST
---@type function[]
local castCallbacks = {}

--- Throttle: minimum interval between cache refreshes
---@type number
local updateInterval = 0.1

--- Last time we refreshed the cache
---@type number
local lastRefresh = 0

local function ResolveRecommendableSpellID()
    if not C_AssistedCombat then
        return nil
    end

    if C_AssistedCombat.GetNextCastSpell then
        local okNext, nextSpellID = pcall(C_AssistedCombat.GetNextCastSpell, true)
        if okNext and RA:IsSpellRecommendable(nextSpellID) then
            local resolvedID = nextSpellID
            if RA.ResolveSpellOverride then
                resolvedID = RA:ResolveSpellOverride(nextSpellID)
            end
            if RA:IsSpellRecommendable(resolvedID) then
                return resolvedID
            end
            return nextSpellID
        end
    end
    return nil
end

------------------------------------------------------------------------
-- Safe API Wrappers
------------------------------------------------------------------------

---Get whether C_AssistedCombat is available in the current client.
---@return boolean isAvailable
---@return string|nil failureReason
function Bridge:IsAvailable()
    if not C_AssistedCombat then
        return false, "C_AssistedCombat namespace does not exist"
    end
    if not C_AssistedCombat.IsAvailable then
        return false, "C_AssistedCombat.IsAvailable not found"
    end
    local ok, available, reason = pcall(C_AssistedCombat.IsAvailable)
    if not ok then
        return false, "pcall error: " .. tostring(available)
    end
    return available == true, reason
end

---Get the current recommended spell from Blizzard.
---Returns cached result if within the throttle window.
---When the recommendation changes, the old value is saved as previousRec.
---@return table|nil recommendation { spellID, texture, name }
function Bridge:GetCurrentRecommendation()
    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return nil
    end

    local now = GetTime()
    if cachedRec and (now - lastRefresh) < updateInterval then
        if RA:IsSpellPassive(cachedRec.spellID) then
            previousRec = cachedRec
            cachedRec = nil
            return nil
        end
        return cachedRec
    end

    -- WoW 12.0 can expose multiple Assisted Combat views at once.
    -- Prefer the immediate cast suggestion, then fall back to action and
    -- rotation context so recommendation slots do not briefly go empty.
    local spellID = ResolveRecommendableSpellID()

    if not spellID then
        previousRec = cachedRec
        cachedRec = nil
        lastRefresh = now
        return nil
    end

    if cachedRec and cachedRec.spellID ~= spellID then
        previousRec = cachedRec
    end

    local texture = 134400
    local name = "Spell#" .. spellID
    local texOk, texResult = pcall(C_Spell.GetSpellTexture, spellID)
    if texOk and texResult then
        texture = texResult
    end
    local infoOk, info = pcall(C_Spell.GetSpellInfo, spellID)
    if infoOk and info and info.name then
        name = info.name
    end

    cachedRec = {
        spellID = spellID,
        texture = texture,
        name = name,
    }
    lastRefresh = now
    return cachedRec
end

---Get the recommendation that was active before the most recent change.
---@return table|nil recommendation { spellID, texture, name }
function Bridge:GetPreviousRecommendation()
    return previousRec
end

---Force-invalidate the cached recommendation.
---Call after a spell cast so the next GetCurrentRecommendation() skips the
---throttle and immediately returns a fresh value from C_AssistedCombat.
function Bridge:InvalidateCache()
    local nextSpellID = ResolveRecommendableSpellID()
    if cachedRec and nextSpellID and nextSpellID ~= cachedRec.spellID then
        previousRec = cachedRec
    else
        previousRec = nil
    end
    cachedRec = nil
    lastRefresh = 0
end

---Get the full rotation spell list from Blizzard.
---@return number[] spellIDs
function Bridge:GetRotationSpells()
    if not C_AssistedCombat or not C_AssistedCombat.GetRotationSpells then
        return {}
    end
    local ok, result = pcall(C_AssistedCombat.GetRotationSpells)
    if not ok or type(result) ~= "table" then
        return {}
    end

    local filtered = {}
    for _, sid in ipairs(result) do
        if not RA:IsSpellPassive(sid) then
            filtered[#filtered + 1] = sid
        end
    end
    return filtered
end

---Get the action spell from Blizzard.
---@return number|nil spellID
function Bridge:GetActionSpell()
    if not C_AssistedCombat or not C_AssistedCombat.GetActionSpell then
        return nil
    end
    local ok, spellID = pcall(C_AssistedCombat.GetActionSpell)
    if not ok then
        return nil
    end
    return spellID
end

---Register a callback for when an assisted combat spell is cast.
---@param callback function(spellID)
function Bridge:OnAssistedSpellCast(callback)
    if type(callback) == "function" then
        castCallbacks[#castCallbacks + 1] = callback
    end
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function Bridge:OnInitialize()
    local cvarVal = GetCVar("assistedCombatIconUpdateRate")
    if cvarVal then
        updateInterval = tonumber(cvarVal) or 0.1
    end
end

function Bridge:OnEnable()
    local available, reason = self:IsAvailable()
    if available then
        RA:PrintDebug("AssistedCombatBridge: C_AssistedCombat is available")
    else
        RA:PrintDebug("AssistedCombatBridge: Not available - " .. tostring(reason))
        RA:PrintDebug("AssistedCombatBridge: AssistCapture glow hooks will be used as fallback")
    end

    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ASSISTED_COMBAT_ACTION_SPELL_CAST", "AssistedCombatBridge", function(_, spellID)
            previousRec = cachedRec
            cachedRec = nil
            for _, cb in ipairs(castCallbacks) do
                local ok, err = pcall(cb, spellID)
                if not ok then
                    RA:PrintError("AssistedCombatBridge callback error: " .. tostring(err))
                end
            end
            eh:Fire("ROTAASSIST_BRIDGE_UPDATED", spellID)
        end)

        eh:Subscribe("CVAR_UPDATE", "AssistedCombatBridge", function(_, cvarName, cvarValue)
            if cvarName == "assistedCombatIconUpdateRate" then
                updateInterval = tonumber(cvarValue) or 0.1
            end
        end)
    end
end
