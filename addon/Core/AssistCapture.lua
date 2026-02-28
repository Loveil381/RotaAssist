------------------------------------------------------------------------
-- RotaAssist - Assisted Highlights Capture (CORE)
-- Hooks Blizzard's ActionButton glow overlay to detect which spells
-- the game engine recommends.  This is the primary data source.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local AssistCapture = {}
RA:RegisterModule("AssistCapture", AssistCapture)

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

--- Maximum number of historical recommendations to keep
local HISTORY_MAX = 10

--- All action bar button name prefixes to scan
local BAR_BUTTON_PREFIXES = {
    "ActionButton",              -- main bar (1-12)
    "MultiBarBottomLeftButton",  -- bottom-left bar
    "MultiBarBottomRightButton", -- bottom-right bar
    "MultiBarRightButton",       -- right bar
    "MultiBarLeftButton",        -- right bar 2
    "MultiBar5Button",           -- extra bar 5 (Dragonflight+)
    "MultiBar6Button",           -- extra bar 6
    "MultiBar7Button",           -- extra bar 7
}

--- Number of buttons per bar
local BUTTONS_PER_BAR = 12

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

--- Currently glowing spell IDs → true
---@type table<number, boolean>
local activeGlows = {}

--- The most recently recommended spellID (or nil)
---@type number|nil
local currentRecommendation = nil

--- Ordered history of recommendations: newest first
---@type table[]  -- { spellID, spellName, timestamp }
local history = {}

--- Map of button frame → actionSlot (cached for performance)
---@type table<Frame, number>
local buttonSlotCache = {}

------------------------------------------------------------------------
-- Button → Spell Resolution
------------------------------------------------------------------------

---Resolve which spellID is on a given action button.
---Uses GetActionInfo → spell type chain.
---@param button Frame An ActionButton frame
---@return number|nil spellID
local function resolveButtonSpellID(button)
    if not button or not button.action then return nil end

    local actionType, id, subType = GetActionInfo(button.action)
    if actionType == "spell" then
        return id
    elseif actionType == "macro" then
        -- Try to resolve the macro's spell
        local spellID = GetMacroSpell(id)
        return spellID
    end
    return nil
end

---Build a spellName string for a given spellID.
---@param spellID number
---@return string
local function getSpellName(spellID)
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    if not ok then info = nil end
    if info then
        return info.name
    end
    return "Spell#" .. spellID
end

------------------------------------------------------------------------
-- History Management
------------------------------------------------------------------------

---Add a spellID to the recommendation history.
---@param spellID number
local function pushHistory(spellID)
    -- Don't duplicate if same as most recent
    if history[1] and history[1].spellID == spellID then
        return
    end

    table.insert(history, 1, {
        spellID   = spellID,
        spellName = getSpellName(spellID),
        timestamp = GetTime(),
    })

    -- Trim to max size
    while #history > HISTORY_MAX do
        history[#history] = nil
    end
end

------------------------------------------------------------------------
-- Glow Hook Logic
------------------------------------------------------------------------

---Called when Blizzard shows an overlay glow on a button.
---@param button Frame The action button receiving glow
local function onOverlayGlowShow(button)
    local spellID = resolveButtonSpellID(button)
    if not spellID then return end

    activeGlows[spellID] = true
    currentRecommendation = spellID
    pushHistory(spellID)

    RA:PrintDebug(string.format("Assist glow ON: %s (%d)",
        getSpellName(spellID), spellID))

    -- Fire custom event for downstream consumers
    local eh = RA:GetModule("EventHandler")
    if eh and eh.Fire then
        eh:Fire("ROTAASSIST_ASSIST_UPDATED", spellID, true)
    end
end

---Called when Blizzard hides an overlay glow from a button.
---@param button Frame The action button losing glow
local function onOverlayGlowHide(button)
    local spellID = resolveButtonSpellID(button)
    if not spellID then return end

    activeGlows[spellID] = nil

    -- If this was the current recommendation, find the next one still glowing
    if currentRecommendation == spellID then
        currentRecommendation = nil
        for glowSpellID in pairs(activeGlows) do
            currentRecommendation = glowSpellID
            break
        end
    end

    RA:PrintDebug(string.format("Assist glow OFF: %s (%d)",
        getSpellName(spellID), spellID))

    local eh = RA:GetModule("EventHandler")
    if eh and eh.Fire then
        eh:Fire("ROTAASSIST_ASSIST_UPDATED", spellID, false)
    end
end

------------------------------------------------------------------------
-- Hook Installation
------------------------------------------------------------------------

---Install hooks on Blizzard's overlay glow functions.
---Must be called after the UI is fully loaded.
local function installHooks()
    -- Hook the global functions that Blizzard uses to show/hide glow
    if ActionButton_ShowOverlayGlow and not AssistCapture._hooked then
        hooksecurefunc("ActionButton_ShowOverlayGlow", onOverlayGlowShow)
        hooksecurefunc("ActionButton_HideOverlayGlow", onOverlayGlowHide)
        AssistCapture._hooked = true
        RA:PrintDebug("Overlay glow hooks installed")
    else
        RA:PrintDebug("ActionButton_ShowOverlayGlow not found — hooks not installed")
    end
end

---Scan all action bars to detect any currently-glowing buttons.
---Used on initial load or /reload to pick up existing state.
local function scanExistingGlows()
    for _, prefix in ipairs(BAR_BUTTON_PREFIXES) do
        for i = 1, BUTTONS_PER_BAR do
            local buttonName = prefix .. i
            local button = _G[buttonName]
            if button and button.overlay and button.overlay:IsShown() then
                onOverlayGlowShow(button)
            end
        end
    end
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function AssistCapture:OnInitialize()
    -- Nothing to do here; hooks are installed on enable
end

function AssistCapture:OnEnable()
    installHooks()
end

function AssistCapture:OnPlayerEnteringWorld(isInitialLogin, isReloadingUi)
    -- Re-scan after loading screen (glows may already be active)
    C_Timer.After(0.5, scanExistingGlows)
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get the currently recommended spellID (from Blizzard glow).
---@return number|nil spellID
---@return string|nil spellName
function AssistCapture:GetCurrentRecommendation()
    if not currentRecommendation then
        return nil, nil
    end
    return currentRecommendation, getSpellName(currentRecommendation)
end

---Get all currently glowing spell IDs.
---@return table<number, boolean> activeGlows Copy of active glow set
function AssistCapture:GetActiveGlows()
    local copy = {}
    for spellID in pairs(activeGlows) do
        copy[spellID] = true
    end
    return copy
end

---Get the recommendation history (newest first).
---@param count number|nil Max entries to return (default: all)
---@return table[] history Array of { spellID, spellName, timestamp }
function AssistCapture:GetHistory(count)
    count = count or HISTORY_MAX
    local result = {}
    for i = 1, math.min(count, #history) do
        result[i] = {
            spellID   = history[i].spellID,
            spellName = history[i].spellName,
            timestamp = history[i].timestamp,
        }
    end
    return result
end

---Check if a specific spell is currently being recommended (glowing).
---@param spellID number
---@return boolean
function AssistCapture:IsSpellRecommended(spellID)
    return activeGlows[spellID] == true
end
