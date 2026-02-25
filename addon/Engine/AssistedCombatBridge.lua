------------------------------------------------------------------------
-- RotaAssist - Assisted Combat Bridge
-- Wraps Blizzard's C_AssistedCombat API (WoW 11.1.7+ / 12.0 core).
-- Primary data source for combat rotation recommendations.
-- C_AssistedCombat を Wrap し、戦闘中推薦スペルを取得する。
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

--- Callbacks registered for ASSISTED_COMBAT_ACTION_SPELL_CAST
---@type function[]
local castCallbacks = {}

--- Throttle: minimum interval between cache refreshes
---@type number
local updateInterval = 0.1  -- default; synced from CVar on enable

--- Last time we refreshed the cache
---@type number
local lastRefresh = 0

------------------------------------------------------------------------
-- Safe API Wrappers (pcall protected, nil-safe)
-- 安全なAPIラッパー (pcall保護、nilセーフ)
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
---Returns cached result if within throttle window.
---Blizzard が推薦する現在のスペルを取得する。
---@return table|nil recommendation { spellID, texture, name }
function Bridge:GetCurrentRecommendation()
    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return nil
    end

    -- Throttle: do not re-query faster than CVar rate
    local now = GetTime()
    if cachedRec and (now - lastRefresh) < updateInterval then
        return cachedRec
    end

    local ok, spellID = pcall(C_AssistedCombat.GetNextCastSpell, true)
    if not ok or not spellID then
        cachedRec = nil
        lastRefresh = now
        return nil
    end

    -- Fetch texture and name safely
    local texture = 134400  -- question mark fallback
    local name    = "Spell#" .. spellID
    local texOk, texResult = pcall(C_Spell.GetSpellTexture, spellID)
    if texOk and texResult then texture = texResult end
    local infoOk, info = pcall(C_Spell.GetSpellInfo, spellID)
    if infoOk and info and info.name then name = info.name end

    cachedRec = {
        spellID = spellID,
        texture = texture,
        name    = name,
    }
    lastRefresh = now
    return cachedRec
end

---Get the full rotation spell list from Blizzard.
---完全なローテーションスペルリストを取得する。
---@return number[] spellIDs
function Bridge:GetRotationSpells()
    if not C_AssistedCombat or not C_AssistedCombat.GetRotationSpells then
        return {}
    end
    local ok, result = pcall(C_AssistedCombat.GetRotationSpells)
    if not ok or type(result) ~= "table" then
        return {}
    end
    return result
end

---Get the action spell from Blizzard.
---@return number|nil spellID
function Bridge:GetActionSpell()
    if not C_AssistedCombat or not C_AssistedCombat.GetActionSpell then
        return nil
    end
    local ok, spellID = pcall(C_AssistedCombat.GetActionSpell)
    if not ok then return nil end
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
    -- Sync throttle interval from CVar (default 0.1s)
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
        RA:PrintDebug("AssistedCombatBridge: Not available — " .. tostring(reason))
        RA:PrintDebug("AssistedCombatBridge: AssistCapture glow hooks will be used as fallback")
    end

    -- Subscribe to the assisted combat cast event
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ASSISTED_COMBAT_ACTION_SPELL_CAST", "AssistedCombatBridge", function(_, spellID)
            -- Invalidate cache so next query is fresh
            cachedRec = nil
            -- Fire all registered callbacks
            for _, cb in ipairs(castCallbacks) do
                local ok, err = pcall(cb, spellID)
                if not ok then
                    RA:PrintError("AssistedCombatBridge callback error: " .. tostring(err))
                end
            end
            -- Fire addon event for downstream (RecommendationManager listens)
            eh:Fire("ROTAASSIST_BRIDGE_UPDATED", spellID)
        end)

        -- Also listen for the update-rate CVar changes
        eh:Subscribe("CVAR_UPDATE", "AssistedCombatBridge", function(_, cvarName, cvarValue)
            if cvarName == "assistedCombatIconUpdateRate" then
                updateInterval = tonumber(cvarValue) or 0.1
            end
        end)
    end
end
