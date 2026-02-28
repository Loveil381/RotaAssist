------------------------------------------------------------------------
-- RotaAssist - Central Event Handler
-- Event dispatcher supporting subscribe/unsubscribe, throttle, and
-- both WoW native events (via AceEvent) and custom addon events.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local EventHandler = {}
RA:RegisterModule("EventHandler", EventHandler)

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

--- Map of eventName → ordered list of { moduleName, callback }
---@type table<string, table[]>
local subscribers = {}

--- Set of WoW events currently registered with AceEvent
---@type table<string, boolean>
local registeredNativeEvents = {}

--- Set of Custom events currently registered with AceEvent
---@type table<string, boolean>
local registeredCustomEvents = {}

--- Throttle state: eventName → { interval, lastFired }
---@type table<string, { interval: number, lastFired: number }>
local throttles = {}

------------------------------------------------------------------------
-- Throttle Helpers
------------------------------------------------------------------------

---Set a throttle interval for an event.  When throttled, only the first
---firing within each interval window will be dispatched.
---@param eventName string
---@param interval number Minimum seconds between dispatches
function EventHandler:SetThrottle(eventName, interval)
    throttles[eventName] = { interval = interval, lastFired = 0 }
end

---Remove throttle for an event.
---@param eventName string
function EventHandler:ClearThrottle(eventName)
    throttles[eventName] = nil
end

---Check whether the event passes the throttle gate.
---@param eventName string
---@return boolean allowed
local function passesThrottle(eventName)
    local t = throttles[eventName]
    if not t then return true end
    local now = GetTime()
    if now - t.lastFired < t.interval then
        return false
    end
    t.lastFired = now
    return true
end

------------------------------------------------------------------------
-- Dispatching
------------------------------------------------------------------------

local function AceEventDispatcher(eventName, ...)
    local list = subscribers[eventName]
    if not list then return end
    if not passesThrottle(eventName) then return end

    for _, entry in ipairs(list) do
        local ok, err = pcall(entry.callback, eventName, ...)
        if not ok then
            RA:PrintError(string.format("Error in %s handler for %s: %s",
                entry.moduleName, eventName, tostring(err)))
        end
    end
end

------------------------------------------------------------------------
-- Subscription API
------------------------------------------------------------------------

---Subscribe a module to an event (WoW native or custom).
---Custom events use the "ROTAASSIST_" prefix convention.
---@param eventName string Event to listen for
---@param moduleName string Name of the subscribing module
---@param callback function function(eventName, ...) to call
function EventHandler:Subscribe(eventName, moduleName, callback)
    if not subscribers[eventName] then
        subscribers[eventName] = {}
    end

    -- Prevent duplicate subscriptions from the same module
    for _, entry in ipairs(subscribers[eventName]) do
        if entry.moduleName == moduleName then
            -- FIX (Issue 5): guard string concat behind debugMode check
            if RA.debugMode then
                RA:PrintDebug(moduleName .. " already subscribed to " .. eventName)
            end
            return
        end
    end

    subscribers[eventName][#subscribers[eventName] + 1] = {
        moduleName = moduleName,
        callback   = callback,
    }

    -- Determine if native or custom
    local isCustom = eventName:find("^ROTAASSIST_")

    if isCustom then
        if not registeredCustomEvents[eventName] then
            RA:RegisterMessage(eventName, AceEventDispatcher)
            registeredCustomEvents[eventName] = true
        end
    else
        if not registeredNativeEvents[eventName] then
            RA:RegisterEvent(eventName, AceEventDispatcher)
            registeredNativeEvents[eventName] = true
        end
    end

    -- FIX (Issue 5): guard string concat behind debugMode check
    if RA.debugMode then
        RA:PrintDebug(moduleName .. " subscribed to " .. eventName)
    end
end

---Unsubscribe a module from an event.
---@param eventName string
---@param moduleName string
function EventHandler:Unsubscribe(eventName, moduleName)
    local list = subscribers[eventName]
    if not list then return end

    for i = #list, 1, -1 do
        if list[i].moduleName == moduleName then
            table.remove(list, i)
        end
    end

    if #list == 0 then
        if registeredNativeEvents[eventName] then
            RA:UnregisterEvent(eventName)
            registeredNativeEvents[eventName] = nil
        elseif registeredCustomEvents[eventName] then
            RA:UnregisterMessage(eventName)
            registeredCustomEvents[eventName] = nil
        end
        subscribers[eventName] = nil
    end
end

---Subscribe a module to multiple events with the same callback.
---@param events string[] List of event names
---@param moduleName string
---@param callback function
function EventHandler:SubscribeMany(events, moduleName, callback)
    for _, eventName in ipairs(events) do
        self:Subscribe(eventName, moduleName, callback)
    end
end

---Unsubscribe a module from multiple events.
---@param events string[]
---@param moduleName string
function EventHandler:UnsubscribeMany(events, moduleName)
    for _, eventName in ipairs(events) do
        self:Unsubscribe(eventName, moduleName)
    end
end

---Unsubscribe a module from ALL events it is subscribed to.
---@param moduleName string
function EventHandler:UnsubscribeAll(moduleName)
    for eventName, list in pairs(subscribers) do
        for i = #list, 1, -1 do
            if list[i].moduleName == moduleName then
                table.remove(list, i)
            end
        end
        if #list == 0 then
            if registeredNativeEvents[eventName] then
                RA:UnregisterEvent(eventName)
                registeredNativeEvents[eventName] = nil
            elseif registeredCustomEvents[eventName] then
                RA:UnregisterMessage(eventName)
                registeredCustomEvents[eventName] = nil
            end
            subscribers[eventName] = nil
        end
    end
end

------------------------------------------------------------------------
-- Dispatch
------------------------------------------------------------------------

---Fire a custom addon event (ROTAASSIST_* prefix recommended).
---@param eventName string Custom event name
---@param ... any Payload arguments
function EventHandler:Fire(eventName, ...)
    -- FIX (Issue 5): Only build and print the debug string when debugMode
    -- is actually on.  Previously the string was concatenated on every call
    -- regardless, causing needless GC pressure on every assist/cooldown event.
    if RA.debugMode then
        RA:PrintDebug("Firing: " .. eventName)
    end
    RA:SendMessage(eventName, ...)
end

------------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------------

function EventHandler:OnEnable()
    -- Central dispatcher for UNIT_SPELLCAST_SUCCEEDED.
    -- Multiple modules need this event (AIInference, CastHistoryRecorder, AccuracyTracker).
    -- AceEvent replaces previous callbacks, so we register ONCE here and re-dispatch
    -- as a custom ROTAASSIST_SPELLCAST_SUCCEEDED event that modules Subscribe to safely.
    RA:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, castGUID, spellID)
        EventHandler:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", unit, castGUID, spellID)
    end)

    -- FIX (P0-Bug1): Central dispatcher for UNIT_SPELLCAST_START.
    -- InterruptAdvisor (and potentially other modules) need this event.
    -- Register ONCE here and re-dispatch as ROTAASSIST_SPELLCAST_START to avoid
    -- individual modules calling RA:RegisterEvent() which overwrites this central handler.
    RA:RegisterEvent("UNIT_SPELLCAST_START", function(_, unit)
        EventHandler:Fire("ROTAASSIST_SPELLCAST_START", unit)
    end)

    -- FIX (P0-Bug1): Central dispatcher for UNIT_SPELLCAST_CHANNEL_START.
    -- Same pattern as above — re-dispatch as ROTAASSIST_CHANNEL_START.
    RA:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", function(_, unit)
        EventHandler:Fire("ROTAASSIST_CHANNEL_START", unit)
    end)

    -- Central dispatchers for spell stop and interrupt events.
    -- 跨模块派发￡◆战斗时打断/停止施法事件
    RA:RegisterEvent("UNIT_SPELLCAST_STOP", function(_, unit)
        EventHandler:Fire("ROTAASSIST_SPELLCAST_STOP", unit)
    end)
    RA:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", function(_, unit)
        EventHandler:Fire("ROTAASSIST_SPELLCAST_INTERRUPTED", unit)
    end)
end

function EventHandler:OnDisable()
    -- Nothing to do
end

------------------------------------------------------------------------
-- Debug: List subscriptions
------------------------------------------------------------------------

---Return a summary of all current subscriptions (for /ra debug).
---@return string
function EventHandler:GetSubscriptionSummary()
    local lines = {}
    for eventName, list in pairs(subscribers) do
        local names = {}
        for _, entry in ipairs(list) do
            names[#names + 1] = entry.moduleName
        end
        lines[#lines + 1] = string.format("  %s → [%s]", eventName, table.concat(names, ", "))
    end
    if #lines == 0 then return "  (none)" end
    table.sort(lines)
    return table.concat(lines, "\n")
end
