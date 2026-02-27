------------------------------------------------------------------------
-- RotaAssist - Cooldown Overlay
-- Tracks major CDs from SpecEnhancements config. Fires alerts when
-- a cooldown is about to become ready.
-- Uses C_Spell.GetSpellCooldown() which is safe during combat.
-- 大技CDのトラッキングとアラート通知。
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local CooldownOverlay = {}
RA:RegisterModule("CooldownOverlay", CooldownOverlay)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

--- Per-spec major cooldown config list from SpecEnhancements
---@type table[]|nil  array of { spellID, alertThreshold }
local trackedCDs = nil

--- Current cooldown states: { [spellID] = { remaining, ready, texture, name, startTime, duration } }
--- Pre-allocated; reused each scan to avoid GC churn.
---@type table<number, table>
local cdStates = {}

--- OnUpdate throttle
local UPDATE_INTERVAL = 0.2  -- 5 Hz
local elapsed   = 0
local updateFrame = nil
local isTracking  = false

------------------------------------------------------------------------
-- Scan Logic
------------------------------------------------------------------------

---Scan all tracked major cooldowns and fire alerts.
local function scanCooldowns()
    if not trackedCDs then return end

    local eh = RA:GetModule("EventHandler")

    for _, cd in ipairs(trackedCDs) do
        local spellID = cd.spellID
        local state   = cdStates[spellID]
        if not state then
            -- FIX (Bug3): Pre-allocate startTime and duration fields so
            -- CooldownBar.lua can call cooldown:SetCooldown(startTime, duration).
            -- 修复：预分配 startTime/duration，供 CooldownBar 调用 SetCooldown。
            state = { remaining = 0, ready = false, texture = 134400, name = "", startTime = 0, duration = 0 }
            cdStates[spellID] = state
        end

        -- WOW 12.0 SECRET VALUE SAFE
        -- FIX (Bug3): Capture all 4 return values including startTime and duration.
        -- 修复：使用 4 返回值版本，同时获取 startTime 和 duration。
        local remaining, ready, cdStart, cdDuration = RA:GetSpellCooldownSafe(spellID)
        if remaining ~= nil then
            state.remaining = remaining
            local wasReady  = state.ready
            state.ready     = ready

            -- FIX (Bug3): Store startTime and duration in the state table
            -- so downstream consumers (CooldownBar widget) can render the sweep.
            -- 保存 startTime/duration 供 UI 的 SetCooldown() 调用。
            state.startTime = cdStart or 0
            state.duration  = cdDuration or 0

            if not wasReady and remaining > 0 and remaining <= (cd.alertThreshold or 5) then
                if eh and eh.Fire then
                    eh:Fire("ROTAASSIST_CD_ALERT", spellID, remaining)
                end
            end
        else
            -- Secret: preserve last known state, don't update
            -- 获取失败（secret value）：保留上次已知状态，不更新
        end

        -- Cache texture/name on first pass
        if state.name == "" then
            local infoOk, info = pcall(C_Spell.GetSpellInfo, spellID)
            if infoOk and info then
                state.name    = info.name or ("Spell#" .. spellID)
                state.texture = info.iconID or 134400
            else
                state.name    = "Spell#" .. spellID
                state.texture = 134400
            end
        end
    end
end

---OnUpdate handler (throttled)
local function onUpdate(_, dt)
    if not isTracking then return end
    elapsed = elapsed + dt
    if elapsed < UPDATE_INTERVAL then return end
    elapsed = 0
    scanCooldowns()
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function CooldownOverlay:OnInitialize()
    updateFrame = CreateFrame("Frame", "RotaAssist_CooldownOverlayFrame")
end

function CooldownOverlay:OnEnable()
    if not updateFrame then return end

    -- Load config from SpecEnhancements when spec changes
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ROTAASSIST_SPEC_CHANGED", "CooldownOverlay", function(_, specInfo)
            self:LoadForSpec(specInfo and specInfo.specID)
        end)
    end

    -- Try loading immediately if spec is already known
    local sd = RA:GetModule("SpecDetector")
    if sd then
        local spec = sd:GetCurrentSpec()
        if spec then self:LoadForSpec(spec.specID) end
    end
end

---Load major cooldown config for a given specID.
---@param specID number|nil
function CooldownOverlay:LoadForSpec(specID)
    trackedCDs = nil
    cdStates   = {}
    isTracking  = false

    if not specID or not RA.SpecEnhancements then return end

    local enhData = RA.SpecEnhancements[specID]
    if enhData and enhData.majorCooldowns then
        trackedCDs = enhData.majorCooldowns
        isTracking  = true
        updateFrame:SetScript("OnUpdate", onUpdate)
        RA:PrintDebug(string.format("CooldownOverlay: Tracking %d major CDs for specID %d",
            #trackedCDs, specID))
    else
        updateFrame:SetScript("OnUpdate", nil)
    end
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get current cooldown states for all tracked major CDs.
---Returns a table keyed by spellID. Each entry contains:
---  remaining (number), ready (boolean), texture (number|string),
---  name (string), startTime (number), duration (number).
---@return table<number, table> states
function CooldownOverlay:GetCooldownStates()
    return cdStates
end

---Get an array of CDs that are currently ready.
---@return table[]
function CooldownOverlay:GetReadyCooldowns()
    local result = {}
    for spellID, state in pairs(cdStates) do
        if state.ready then
            result[#result + 1] = {
                spellID = spellID,
                name    = state.name,
                texture = state.texture,
            }
        end
    end
    return result
end
