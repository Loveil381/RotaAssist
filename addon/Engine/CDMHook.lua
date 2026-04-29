------------------------------------------------------------------------
-- RotaAssist - CDM (Cooldown Manager / Essential Cooldown Viewer) Hook
-- WoW 12.0 introduced Blizzard's default `EssentialCooldownViewer`
-- Edit-Mode frame (a.k.a. "CDM"). RotaAssist co-exists with it: this
-- module hooks the frame's Update method via hooksecurefunc, reads the
-- set of spellIDs currently displayed by Blizzard, and re-broadcasts it
-- as `ROTAASSIST_CDM_UPDATE` so downstream modules (CooldownOverlay,
-- CooldownPanel, SmartQueueManager) can stay in sync with what the
-- player is seeing in the Blizzard CD viewer.
--
-- Design contract:
--   * Read-only co-existence; we never mutate the Blizzard frame.
--   * If `EssentialCooldownViewer` is not present (older client, addon
--     disabled, future API rename), the module silently no-ops and
--     emits nothing. Logs a single INFO at OnEnable time.
--   * Payload: { visibleSpellIDs = { [spellID]=true, ... } }
--   * Output throttled to 0.2s and deduplicated against the last
--     emitted set so identical updates do not re-fire.
--
-- ECV API surface (12.0, defensively probed):
--   EssentialCooldownViewer:Update()        — primary refresh hook
--   EssentialCooldownViewer:GetCooldownIDs()
--   EssentialCooldownViewer.cooldownPool    — FramePool of live items
--   each pooled frame may expose .spellID / :GetSpellID()
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local CDMHook = {}
RA:RegisterModule("CDMHook", CDMHook)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

--- Last emitted set, kept for dedup comparison.
---@type table<number, boolean>
local lastEmitted = {}

--- Whether `hooksecurefunc` has already been installed.
---@type boolean
local hookInstalled = false

--- Throttle window
local THROTTLE_INTERVAL = 0.2
local lastFireTime = 0

--- Whether the Blizzard frame has been detected; cached for /ra debug.
---@type boolean
local ecvDetected = false

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

---Compare two spellID-set tables for equality.
---@param a table<number, boolean>
---@param b table<number, boolean>
---@return boolean equal
local function setsEqual(a, b)
    for k in pairs(a) do
        if not b[k] then return false end
    end
    for k in pairs(b) do
        if not a[k] then return false end
    end
    return true
end

---Read the current visible spellID set from EssentialCooldownViewer.
---Probes multiple possible accessors so we degrade gracefully across
---minor patch revisions. Returns an empty table if nothing readable.
---@param ecv table  Blizzard EssentialCooldownViewer global
---@return table<number, boolean>
local function readVisibleSpellIDs(ecv)
    local out = {}

    -- Path 1: explicit accessor
    if type(ecv.GetCooldownIDs) == "function" then
        local ok, list = pcall(ecv.GetCooldownIDs, ecv)
        if ok and type(list) == "table" then
            for _, sid in ipairs(list) do
                if type(sid) == "number" and sid > 0 then
                    out[sid] = true
                end
            end
            if next(out) then return out end
        end
    end

    -- Path 2: cooldownPool / itemFramePool with EnumerateActive
    local pool = ecv.cooldownPool or ecv.itemFramePool or ecv.framePool
    if pool and type(pool.EnumerateActive) == "function" then
        local ok, iter = pcall(pool.EnumerateActive, pool)
        if ok and type(iter) == "function" then
            for itemFrame in iter do
                local sid = nil
                if type(itemFrame) == "table" then
                    if type(itemFrame.GetSpellID) == "function" then
                        local sok, s = pcall(itemFrame.GetSpellID, itemFrame)
                        if sok then sid = s end
                    end
                    if not sid then sid = rawget(itemFrame, "spellID") end
                end
                if type(sid) == "number" and sid > 0 then
                    out[sid] = true
                end
            end
        end
    end

    return out
end

---Build a new, immutable-ish copy so subscribers can't mutate our cache.
---@param src table<number, boolean>
---@return table<number, boolean>
local function copySet(src)
    local copy = {}
    for k, v in pairs(src) do copy[k] = v end
    return copy
end

------------------------------------------------------------------------
-- Hook callback
------------------------------------------------------------------------

local function onECVUpdate()
    local ecv = _G.EssentialCooldownViewer
    if type(ecv) ~= "table" then return end

    local now = (GetTime and GetTime()) or 0
    if (now - lastFireTime) < THROTTLE_INTERVAL then return end

    local visible = readVisibleSpellIDs(ecv)
    if setsEqual(visible, lastEmitted) then return end

    lastEmitted = visible
    lastFireTime = now

    local eh = RA:GetModule("EventHandler")
    if eh and eh.Fire then
        -- Subscribers receive { visibleSpellIDs = {...} } as a single payload table.
        eh:Fire("ROTAASSIST_CDM_UPDATE", { visibleSpellIDs = copySet(visible) })
    end
end

---Attempt to install hooksecurefunc on ECV's update method.
---Idempotent: subsequent calls are no-ops once installed.
---@return boolean installed
local function tryInstallHook()
    if hookInstalled then return true end
    local ecv = _G.EssentialCooldownViewer
    if type(ecv) ~= "table" then return false end

    -- Probe for the most likely refresh method names in order.
    local methodName = nil
    if type(ecv.Update) == "function" then
        methodName = "Update"
    elseif type(ecv.RefreshLayout) == "function" then
        methodName = "RefreshLayout"
    elseif type(ecv.UpdateLayout) == "function" then
        methodName = "UpdateLayout"
    end

    if not methodName then return false end

    local hsf = _G.hooksecurefunc
    if type(hsf) ~= "function" then
        -- Test environments without hooksecurefunc fall back to a direct wrap.
        local orig = ecv[methodName]
        ecv[methodName] = function(...)
            local r1, r2, r3 = orig(...)
            local ok, err = pcall(onECVUpdate)
            if not ok then
                RA:PrintDebug("CDMHook: handler error: " .. tostring(err))
            end
            return r1, r2, r3
        end
    else
        local ok, err = pcall(hsf, ecv, methodName, onECVUpdate)
        if not ok then
            RA:PrintDebug("CDMHook: hooksecurefunc failed: " .. tostring(err))
            return false
        end
    end

    hookInstalled = true
    ecvDetected   = true
    return true
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function CDMHook:OnInitialize()
    -- Reset module state in case of /reload during the same Lua VM.
    lastEmitted   = {}
    hookInstalled = false
    ecvDetected   = false
    lastFireTime  = 0
end

function CDMHook:OnEnable()
    if tryInstallHook() then
        RA:PrintDebug("CDMHook: hooked EssentialCooldownViewer; broadcasting ROTAASSIST_CDM_UPDATE")
        -- Fire once on enable so subscribers get an initial state.
        onECVUpdate()
    else
        -- Graceful degradation: log once at INFO and stay silent thereafter.
        RA:PrintDebug("CDMHook: EssentialCooldownViewer not present; CDM hook idle")
    end

    -- If ECV was loaded after us (LoD UI), retry once on PLAYER_ENTERING_WORLD.
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("PLAYER_ENTERING_WORLD", "CDMHook", function()
            if not hookInstalled then tryInstallHook() end
        end)
    end
end

function CDMHook:OnDisable()
    -- hooksecurefunc cannot be unhooked, so we just clear our state and
    -- rely on the closure check (RA:GetModule("EventHandler") + payload
    -- equality) to no-op subsequent fires.
    lastEmitted  = {}
    lastFireTime = 0
end

------------------------------------------------------------------------
-- Public API (debug / testing)
------------------------------------------------------------------------

---Whether the Blizzard ECV frame was found and hooked.
---@return boolean
function CDMHook:IsActive()
    return hookInstalled
end

---Whether the Blizzard ECV global was ever detected.
---@return boolean
function CDMHook:IsECVPresent()
    return ecvDetected
end

---Snapshot of the most-recently emitted visible spellID set.
---@return table<number, boolean>
function CDMHook:GetLastVisibleSet()
    return copySet(lastEmitted)
end

---Force a re-scan of the ECV frame and emit if changed.
---Test-only: bypasses throttle.
function CDMHook:ForceUpdate()
    lastFireTime = 0
    onECVUpdate()
end
