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

-- FIX (Bug2): Cache the *previous* recommendation so AccuracyTracker
-- can compare against what was shown before the cast succeeded.
-- 修复：缓存上一帧推荐，供 AccuracyTracker 施法成功后比对。
---@type table|nil
local previousRec = nil

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
---When the recommendation changes, the old value is saved as previousRec.
---Blizzard が推薦する現在のスペルを取得する。推薦が変わる前の値を previousRec に保存する。
---@return table|nil recommendation { spellID, texture, name }
function Bridge:GetCurrentRecommendation()
    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return nil
    end

    -- Throttle: do not re-query faster than CVar rate
    local now = GetTime()
    if cachedRec and (now - lastRefresh) < updateInterval then
        -- FIX: If cached rec is passive, clear it immediately — stale passive cache is the root bug.
        -- 修复：如果缓存推荐是被动技能，立刻清除（防止被动推荐永久卡住）
        if RA:IsSpellPassive(cachedRec.spellID) then
            previousRec = cachedRec
            cachedRec = nil
            return nil
        end
        return cachedRec
    end

    local ok, spellID = pcall(C_AssistedCombat.GetNextCastSpell, true)
    if not ok or not spellID then
        -- FIX (Bug2): Save previous before clearing
        -- 获取失败时保留上一次推荐
        previousRec  = cachedRec
        cachedRec    = nil
        lastRefresh  = now
        return nil
    end

    -- 【新增】过滤覆盖型被动：检测天赋是否将主动技能替换为被动（如 丝缕交织 替换 时间停止）
    -- Filter overridden passives: check if talent replaces active with passive (Time Skip -> Interwoven Threads)
    if RA.ResolveSpellOverride then
        local resolvedID, wasOverridden = RA:ResolveSpellOverride(spellID)
        if wasOverridden and RA:IsSpellPassive(resolvedID) then
            previousRec = cachedRec
            cachedRec = nil
            lastRefresh = now
            return nil
        end
    end

    -- 【新增】过滤被动技能：Blizzard API 偶尔会返回被动技能（如 Demon Blades 203555）
    -- Filter passive spells: Blizzard API occasionally returns passives
    if RA:IsSpellPassive(spellID) then
        -- FIX: Clear cache to prevent stale passive from sticking permanently
        -- 修复：清除缓存而非保留旧推荐，防止被动推荐永久粘滞
        previousRec = cachedRec
        cachedRec = nil
        lastRefresh = now
        return nil
    end

    -- 【新增】运行时可用性检查：C_Spell.IsSpellUsable 拦截天赋替换型被动
    -- Runtime usability gate: catches talent-replacement passives that IsSpellPassive misses
    if C_Spell and C_Spell.IsSpellUsable then
        local usableOk, usable = pcall(C_Spell.IsSpellUsable, spellID)
        if usableOk and usable == false then
            previousRec = cachedRec
            cachedRec = nil
            lastRefresh = now
            return nil
        end
    end

    -- FIX (Bug2): Only update previousRec when the spell actually changes
    -- 仅在推荐技能发生变化时更新 previousRec，避免无意义覆盖
    if cachedRec and cachedRec.spellID ~= spellID then
        previousRec = cachedRec
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

---Get the recommendation that was active before the most recent change.
---Returns nil if there has been no prior recommendation yet.
---获取上一帧的 Blizzard 推荐（切换前），供准确度比对使用。
---@return table|nil recommendation { spellID, texture, name }
function Bridge:GetPreviousRecommendation()
    return previousRec
end

---Force-invalidate the cached recommendation.
---Call after a spell cast so the next GetCurrentRecommendation() skips the throttle
---and immediately returns a fresh value from C_AssistedCombat.
---施法后调用以立刻失效缓存，下次 GetCurrentRecommendation 不受节流限制。
function Bridge:InvalidateCache()
    previousRec = cachedRec
    cachedRec   = nil
    lastRefresh = 0
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
    -- 【新增】过滤被动技能，只返回非被动 spell ID
    -- Filter passive spells from the rotation list
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
            -- FIX (Bug2): Save current as previous before invalidating cache
            -- 在失效缓存前先把当前推荐存为 previousRec
            previousRec = cachedRec
            cachedRec   = nil
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
