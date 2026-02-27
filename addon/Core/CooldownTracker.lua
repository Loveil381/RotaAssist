------------------------------------------------------------------------
-- RotaAssist - Cooldown Tracker
-- Tracks whitelisted spell cooldowns via C_Spell.GetSpellCooldown().
-- Updates are throttled to max 10/sec using an OnUpdate accumulator.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local CooldownTracker = {}
RA:RegisterModule("CooldownTracker", CooldownTracker)

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

--- Minimum interval between full cooldown scans (seconds)
local UPDATE_INTERVAL = 0.1  -- 10 Hz max

--- GCD duration threshold: cooldowns shorter than this are treated as GCD
local GCD_THRESHOLD = 1.5

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

--- The whitelist table, loaded from Data/WhitelistSpells.lua
---@type table<number, table>|nil
local whitelist = nil

--- Current cooldown states: { [spellID] = { start, duration, remaining, ready } }
---@type table<number, table>
local cooldownStates = {}

--- Accumulator for OnUpdate throttling
local elapsed = 0

--- Internal OnUpdate frame
--- FIX (Issue 7): Declare as upvalue; created in OnInitialize (not at file
--- scope) so CreateFrame() runs after ADDON_LOADED when UIParent is fully
--- ready, avoiding potential frame-naming collisions with other addons.
local updateFrame = nil

--- Whether the tracker is actively running
local isTracking = false

------------------------------------------------------------------------
-- Cooldown Query
------------------------------------------------------------------------

---Query the cooldown for a single whitelisted spell.
---@param spellID number
---@param now number Current GetTime() — passed in to avoid per-spell calls
---@return table state { start, duration, remaining, ready, name, icon }
local function querySpellCooldown(spellID, now)
    local state = cooldownStates[spellID] or {}

    -- WOW 12.0 SECRET VALUE SAFE
    local remaining, ready, cdStart, cdDuration = RA:GetSpellCooldownSafe(spellID)

    if remaining ~= nil then
        state.start = cdStart or 0
        state.duration = cdDuration or 0
        state.remaining = remaining
        state.ready = ready
        state.isEnabled = true
    else
        -- Secret: preserve last known state to avoid false "ready" flashes
        if not state.start then
            state.start = 0
            state.duration = 0
            state.remaining = 0
            state.ready = true
            state.isEnabled = true
        end
        -- Otherwise keep state unchanged (last known values)
    end

    -- Cache spell metadata (only on first query)
    if not state.name then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and info then
            state.name = info.name
            state.icon = info.iconID
        else
            state.name = "Spell#" .. spellID
            state.icon = 134400  -- question mark icon
        end
    end

    state.spellID = spellID
    cooldownStates[spellID] = state
    return state
end

------------------------------------------------------------------------
-- Full Scan
------------------------------------------------------------------------

---Scan all whitelisted spells and update cooldown states.
local function scanAllCooldowns()
    if not whitelist then return end

    -- FIX (Suggestion 11): call GetTime() once and pass it into each query
    local now = GetTime()
    local anyChanged = false

    for spellID, spellData in pairs(whitelist) do
        local oldReady = cooldownStates[spellID] and cooldownStates[spellID].ready
        local state = querySpellCooldown(spellID, now)

        -- Copy static data from whitelist
        state.class     = spellData.class
        state.specID    = spellData.specID
        state.cdSeconds = spellData.cdSeconds

        if state.ready ~= oldReady then
            anyChanged = true
        end
    end

    -- Notify listeners if anything changed
    if anyChanged then
        local eh = RA:GetModule("EventHandler")
        if eh and eh.Fire then
            eh:Fire("ROTAASSIST_COOLDOWNS_UPDATED")
        end
    end
end

------------------------------------------------------------------------
-- OnUpdate Throttle
------------------------------------------------------------------------

local function onUpdate(_, dt)
    if not isTracking then return end

    elapsed = elapsed + dt
    if elapsed < UPDATE_INTERVAL then return end
    elapsed = 0

    scanAllCooldowns()
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function CooldownTracker:OnInitialize()
    -- FIX (Issue 7): Create the polling frame here, after ADDON_LOADED,
    -- instead of at file-scope.  This ensures UIParent is fully ready and
    -- avoids frame-naming races with other addons on load.
    updateFrame = CreateFrame("Frame", "RotaAssist_CooldownFrame")

    -- Load the whitelist from the Data module (Data/ loads before Engine/
    -- after .toc fix, so RA.WhitelistSpells is guaranteed to exist here).
    whitelist = RA.WhitelistSpells
    if not whitelist then
        RA:PrintWarning("WhitelistSpells data not loaded — CooldownTracker disabled")
        return
    end

    -- Pre-populate cooldown states for all whitelisted spells
    local now = GetTime()
    for spellID in pairs(whitelist) do
        querySpellCooldown(spellID, now)
    end

    RA:PrintDebug(string.format("CooldownTracker: tracking %d spells",
        self:GetTrackedCount()))
end

function CooldownTracker:OnEnable()
    if not updateFrame then return end  -- guard if OnInitialize bailed early

    -- Subscribe to relevant events
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("SPELL_UPDATE_COOLDOWN", "CooldownTracker", function()
            scanAllCooldowns()
        end)
    end

    -- Start OnUpdate polling as a fallback
    updateFrame:SetScript("OnUpdate", onUpdate)
    isTracking = true
end

function CooldownTracker:OnPlayerEnteringWorld()
    -- Refresh all cooldowns after loading screen
    C_Timer.After(0.3, scanAllCooldowns)
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get the cooldown state of a specific spell.
---@param spellID number
---@return table|nil state { spellID, name, icon, start, duration, remaining, ready, class, specID, cdSeconds }
function CooldownTracker:GetCooldownState(spellID)
    return cooldownStates[spellID]
end

---Get all tracked cooldown states.
---@return table<number, table> states
function CooldownTracker:GetAllCooldowns()
    return cooldownStates
end

---Get list of spells that are currently off cooldown (ready).
---@return table[] readySpells Array of { spellID, name, icon }
function CooldownTracker:GetReadySpells()
    local result = {}
    for spellID, state in pairs(cooldownStates) do
        if state.ready then
            result[#result + 1] = {
                spellID = spellID,
                name    = state.name,
                icon    = state.icon,
            }
        end
    end
    return result
end

---Get the number of tracked spells.
---@return number
function CooldownTracker:GetTrackedCount()
    local count = 0
    for _ in pairs(cooldownStates) do
        count = count + 1
    end
    return count
end

---Check if the player has overridden tracking for a spell.
---@param spellID number
---@return boolean isTracked
function CooldownTracker:IsSpellTracked(spellID)
    -- Check user override first
    local cdDb = RA.db and RA.db.profile and RA.db.profile.cooldowns
    if cdDb and cdDb.trackedSpells then
        local override = cdDb.trackedSpells[spellID]
        if override ~= nil then
            return override
        end
    end
    -- Default: tracked if in whitelist
    return whitelist and whitelist[spellID] ~= nil
end

---Pause or resume tracking.
---@param enabled boolean
function CooldownTracker:SetEnabled(enabled)
    isTracking = enabled
    if not updateFrame then return end
    if not enabled then
        updateFrame:SetScript("OnUpdate", nil)
    else
        updateFrame:SetScript("OnUpdate", onUpdate)
    end
end
