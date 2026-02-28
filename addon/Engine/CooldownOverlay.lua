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

        -- Charge-spell priority: check charges first for accurate state
        local chargeHandled = false
        do
            local chOk, chInfo = pcall(C_Spell.GetSpellCharges, spellID)
            if chOk and chInfo and type(chInfo) == "table" then
                local mc = chInfo.maxCharges
                -- SECRET VALUE GUARD: maxCharges 和 currentCharges 可能是 secret
                if mc and not issecretvalue(mc) and mc > 1 then
                    chargeHandled = true
                    local cc = chInfo.currentCharges
                    if cc and not issecretvalue(cc) and cc > 0 then
                        state.remaining = 0
                        state.ready = true
                        state.startTime = 0
                        state.duration = 0
                    else
                        local cst = chInfo.cooldownStartTime
                        local cdur = chInfo.cooldownDuration
                        if cst and cdur
                           and not issecretvalue(cst) and not issecretvalue(cdur)
                           and cdur > 0 then
                            local cRem = (cst + cdur) - GetTime()
                            if cRem <= 0 then
                                state.remaining = 0
                                state.ready = true
                            else
                                state.remaining = cRem
                                state.ready = false
                            end
                            state.startTime = cst
                            state.duration = cdur
                        else
                            -- 字段是 secret 或无效：放弃 charge 路径，走标准 CD 检查
                            chargeHandled = false
                        end
                    end
                end
                -- 如果 maxCharges 是 secret 或 <= 1，chargeHandled 仍为 false，走标准路径
            end
        end

        if not chargeHandled then
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
                -- Secret value: 不能直接读 CD。改用施法历史 + WhitelistSpells.cdSeconds 估算。
                -- Secret CD: fall back to cast-history estimation using WhitelistSpells.cdSeconds.
                local wsInfo = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
                if wsInfo and wsInfo.cdSeconds and wsInfo.cdSeconds > 0 then
                    local recorder = RA:GetModule("CastHistoryRecorder")
                    local lastCastTime = nil
                    if recorder then
                        local recent = recorder:GetRecentCasts(20)
                        for _, cast in ipairs(recent) do
                            if cast.spellID == spellID then
                                lastCastTime = cast.timestamp
                                break
                            end
                        end
                    end
                    if lastCastTime then
                        local elapsed = GetTime() - lastCastTime
                        local estimatedRemaining = wsInfo.cdSeconds - elapsed
                        if estimatedRemaining <= 0 then
                            state.remaining = 0
                            state.ready     = true
                        else
                            state.remaining = estimatedRemaining
                            state.ready     = false
                        end
                    else
                        -- 从未施放过：保持就绪（合理默认，技能在初始状态下可用）
                        -- Never cast this session: assume ready (spell available by default).
                        state.remaining = 0
                        state.ready     = true
                    end
                end
                -- 无 cdSeconds 或 cdSeconds == 0：保留旧状态（现有行为）
                -- No cdSeconds info: leave state unchanged (preserve previous behavior).
            end
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

        -- 天赋改变时重新扫描（同专精内换天赋不触发 SPEC_CHANGED）
        -- Reload when talents change within the same spec (no SPEC_CHANGED fires)
        eh:Subscribe("PLAYER_TALENT_UPDATE", "CooldownOverlay", function()
            local sd = RA:GetModule("SpecDetector")
            if sd then
                local spec = sd:GetCurrentSpec()
                if spec then self:LoadForSpec(spec.specID) end
            end
        end)

        -- 收到 CD 变化通知时立刻扫描（不等 0.2s 节流）
        -- Immediately scan when any CD state changes, triggered by SPELL_UPDATE_COOLDOWN.
        local cdEventThrottle = 0
        eh:Subscribe("ROTAASSIST_CD_UPDATED", "CooldownOverlay", function()
            if not isTracking then return end
            local now = GetTime()
            if now - cdEventThrottle < 0.05 then return end
            cdEventThrottle = now
            scanCooldowns()
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

    local enhData  = RA.SpecEnhancements[specID]
    local combined = {}
    local seen     = {}

    -- 1. Load explicit major cooldowns configured in SpecEnhancements
    -- 跳过未学习的天赋技能 / Skip unlearned talent spells
    if enhData and enhData.majorCooldowns then
        for _, cd in ipairs(enhData.majorCooldowns) do
            if not seen[cd.spellID] then
                local isKnown = true
                if IsPlayerSpell then
                    isKnown = IsPlayerSpell(cd.spellID)
                    if not isKnown and IsSpellKnown then
                        isKnown = IsSpellKnown(cd.spellID)
                    end
                end
                if isKnown then
                    combined[#combined + 1] = cd
                    seen[cd.spellID] = true
                end
            end
        end
    end

    -- 2. Supplement with class-wide WhitelistSpells (for blind-spot CD detection)
    -- 使用 WhitelistSpells 补充追踪列表，使 APLEngine 能获得所有技能的真实 CD 状态
    if RA.WhitelistSpells then
        -- Determine current classFile for matching
        local classFile = nil
        local sd = RA:GetModule("SpecDetector")
        if sd then
            local spec = sd:GetCurrentSpec()
            classFile = spec and spec.classFile  -- 字符串 "DEMONHUNTER"
        end

        for sid, ws in pairs(RA.WhitelistSpells) do
            if not seen[sid] then
                local classMatch = (not ws.class) or (classFile and ws.class == classFile)
                local specMatch  = (not ws.specID) or (ws.specID == specID)
                if classMatch and specMatch and ws.cdSeconds and ws.cdSeconds >= 3 then
                    -- 跳过未学习的天赋技能 / Skip unlearned talent spells
                    local isKnown = true
                    if IsPlayerSpell then
                        isKnown = IsPlayerSpell(sid)
                        -- 备用：部分变体技能 IsPlayerSpell 返回 false 但 IsSpellKnown 返回 true
                        -- Fallback: some variant spells return false from IsPlayerSpell but true from IsSpellKnown
                        if not isKnown and IsSpellKnown then
                            isKnown = IsSpellKnown(sid)
                        end
                    end
                    if isKnown then
                        combined[#combined + 1] = { spellID = sid, alertThreshold = 5 }
                        seen[sid] = true
                    end
                end
            end
        end
    end

    if #combined > 0 then
        trackedCDs = combined
        isTracking  = true
        updateFrame:SetScript("OnUpdate", onUpdate)
        RA:PrintDebug(string.format("CooldownOverlay: Tracking %d CDs for specID %d (incl. whitelist)",
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

---Force-refresh cooldown state for a specific spell immediately after it is cast.
---Avoids the 0.2s polling delay. On secret-value responses, sets ready=false using
---WhitelistSpells.cdSeconds as the estimated cooldown duration.
---施法后立刻刷新单个技能的 CD 状态；secret value 时用 WhitelistSpells.cdSeconds 估算。
---@param spellID number
function CooldownOverlay:RefreshSpellCooldown(spellID)
    if not spellID then return end
    -- Ensure there is a state slot to write into
    local state = cdStates[spellID]
    if not state then
        state = { remaining = 0, ready = false, texture = 134400, name = "", startTime = 0, duration = 0 }
        cdStates[spellID] = state
    end

    local remaining, ready, cdStart, cdDuration = RA:GetSpellCooldownSafe(spellID)
    if remaining ~= nil then
        -- CD data readable: use it directly
        state.remaining = remaining
        state.ready     = ready
        state.startTime = cdStart or 0
        state.duration  = cdDuration or 0
    else
        -- Secret value: spell was just cast, so mark it on-cooldown using WhitelistSpells baseline.
        -- Secret value：刚施放过，用 WhitelistSpells.cdSeconds 直接标记为 CD 中
        local wsInfo = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
        if wsInfo and wsInfo.cdSeconds and wsInfo.cdSeconds > 0 then
            local now = GetTime()
            state.remaining = wsInfo.cdSeconds
            state.ready     = false
            state.startTime = now
            state.duration  = wsInfo.cdSeconds
        end
        -- No cdSeconds info: leave state unchanged
    end
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
