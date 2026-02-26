------------------------------------------------------------------------
-- RotaAssist - Cast History Recorder
-- 施法历史记录器 / Cast History Recorder
-- Records player's own spell casts using NON-SECRET
-- UNIT_SPELLCAST_SUCCEEDED event for pattern analysis.
-- プレイヤーのスキル履歴をUNIT_SPELLCAST_SUCCEEDEDで記録する。
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local CastHistoryRecorder = {}
RA:RegisterModule("CastHistoryRecorder", CastHistoryRecorder)

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local RING_CAPACITY  = 200   -- 环形缓冲区容量 / ring buffer capacity
local SAVE_CAPACITY  = 500   -- 持久化上限 / max entries persisted per spec

------------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------------

---@type table[] Ring buffer: {spellID, timestamp, wasRecommended}
local ringBuffer = {}
local head = 0        -- 写入指针 / write pointer (0 = empty)
local count = 0       -- 当前元素数 / current element count

-- 精确度计数 / accuracy counters
local sessionTotal   = 0
local sessionMatches = 0

-- Cached rotation spells from C_AssistedCombat (refreshed on spec change)
-- These are the core rotational abilities that should be recorded in history.
---@type table<number, boolean>|nil
local cachedRotationSpells = nil

------------------------------------------------------------------------
-- Ring Buffer Helpers (无 table.insert / no table.insert)
------------------------------------------------------------------------

---Push a new entry into the ring buffer.
---将新条目压入环形缓冲区。
---@param spellID number
---@param timestamp number
---@param wasRecommended boolean
local function RingPush(spellID, timestamp, wasRecommended)
    head = head + 1
    if head > RING_CAPACITY then head = 1 end
    -- 复用已有slot / reuse existing slot
    if not ringBuffer[head] then
        ringBuffer[head] = { 0, 0, false }
    end
    ringBuffer[head][1] = spellID
    ringBuffer[head][2] = timestamp
    ringBuffer[head][3] = wasRecommended
    count = math.min(count + 1, RING_CAPACITY)
end

---Read N most-recent entries from ring buffer (newest first).
---从环形缓冲区读取最近N条（最新在前）。
---@param n number
---@return table[] entries {{spellID, timestamp}, ...}
local function RingRead(n)
    local result = {}
    n = math.min(n, count)
    local ptr = head
    for i = 1, n do
        if ptr < 1 then ptr = RING_CAPACITY end
        local entry = ringBuffer[ptr]
        if entry then
            result[i] = { spellID = entry[1], timestamp = entry[2] }
        end
        ptr = ptr - 1
    end
    return result
end

------------------------------------------------------------------------
-- Event Handler
------------------------------------------------------------------------

---Handles UNIT_SPELLCAST_SUCCEEDED for player.
---プレイヤーのUNIT_SPELLCAST_SUCCEEDEDを処理する。
---@param _ any
---@param unit string
---@param _ any
---@param spellID number
---Refresh the cached rotation spells from C_AssistedCombat.GetRotationSpells().
---ローテーションスペルキャッシュを更新する。
local function RefreshRotationSpellCache()
    cachedRotationSpells = {}
    local bridge = RA:GetModule("AssistedCombatBridge")
    if bridge then
        local spells = bridge:GetRotationSpells()
        if spells then
            for _, sid in ipairs(spells) do
                cachedRotationSpells[sid] = true
            end
        end
    end
end

local function OnSpellCastSucceeded(_, unit, _, spellID)
    if unit ~= "player" then return end

    -- 过滤自动攻击 / filter auto attack
    if spellID == 6603 then return end

    -- 过滤非战斗技能 / filter non-combat spells
    -- Record if spell is in the rotation pool OR in WhitelistSpells (major CDs)
    local isRotation = cachedRotationSpells and cachedRotationSpells[spellID]
    local isWhitelisted = RA.WhitelistSpells and RA.WhitelistSpells[spellID]
    if not isRotation and not isWhitelisted then return end

    local now = GetTime()

    -- 检测当前推荐 / check current Blizzard recommendation
    local wasRecommended = false
    local bridge = RA:GetModule("AssistedCombatBridge")
    if bridge then
        local rec = bridge:GetCurrentRecommendation()
        if rec and rec.spellID then
            wasRecommended = (rec.spellID == spellID)
            -- 如果 spellID 不匹配，尝试名称匹配 / fallback to name match
            if not wasRecommended then
                local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
                if ok and info and info.name and info.name == rec.name then
                    wasRecommended = true
                end
            end
        end
    end

    -- 获取前一个技能用于 Markov / get previous spell for Markov
    local prevSpellID = nil
    if count > 0 and ringBuffer[head] then
        prevSpellID = ringBuffer[head][1]
    end

    -- 写入缓冲区 / push to ring buffer
    RingPush(spellID, now, wasRecommended)

    -- 更新精确度 / update accuracy
    if bridge and bridge:GetCurrentRecommendation() then
        sessionTotal = sessionTotal + 1
        if wasRecommended then
            sessionMatches = sessionMatches + 1
        end
    end

    -- 通知 NeuralPredictor 更新 Markov / notify NeuralPredictor
    if prevSpellID and prevSpellID ~= 0 then
        local np = RA:GetModule("NeuralPredictor")
        if np and np.UpdateMarkovMatrix then
            np:UpdateMarkovMatrix(prevSpellID, spellID)
        end
    end
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Get last N casts (newest first).
---获取最近N次施法（最新在前）。
---@param n number|nil Default 10
---@return table[] entries {{spellID, timestamp}, ...}
function CastHistoryRecorder:GetRecentCasts(n)
    return RingRead(n or 10)
end

---Get most recent spellID.
---获取最近一次施法ID。
---@return number|nil spellID
function CastHistoryRecorder:GetLastSpellID()
    if count == 0 then return nil end
    return ringBuffer[head] and ringBuffer[head][1] or nil
end

---Get Nth-to-last spellID (1 = last, 2 = second-to-last, ...).
---获取倒数第N个施法ID。
---@param n number
---@return number spellID or 0
function CastHistoryRecorder:GetNthLastSpellID(n)
    if n > count then return 0 end
    local ptr = head - (n - 1)
    if ptr < 1 then ptr = ptr + RING_CAPACITY end
    return ringBuffer[ptr] and ringBuffer[ptr][1] or 0
end

---Get time since last cast.
---获取距上次施法的秒数。
---@return number seconds
function CastHistoryRecorder:GetTimeSinceLastCast()
    if count == 0 then return 999 end
    local entry = ringBuffer[head]
    if not entry then return 999 end
    return GetTime() - entry[2]
end

---Get session accuracy stats.
---获取本次战斗精确度统计。
---@return table {total, matches, percentage}
function CastHistoryRecorder:GetAccuracy()
    local pct = 0
    if sessionTotal > 0 then pct = (sessionMatches / sessionTotal) * 100 end
    return { total = sessionTotal, matches = sessionMatches, percentage = pct }
end

---Hash of last N spellIDs for pattern matching.
---最近N个技能ID的哈希值，用于模式匹配。
---@param n number
---@return number hash
function CastHistoryRecorder:GetCastSequenceHash(n)
    n = math.min(n or 5, count)
    local hash = 0
    local ptr = head
    for i = 1, n do
        if ptr < 1 then ptr = RING_CAPACITY end
        local entry = ringBuffer[ptr]
        if entry then
            hash = bit.bxor(hash, bit.lshift(entry[1] % 65536, ((i - 1) * 4) % 16))
        end
        ptr = ptr - 1
    end
    return hash
end

---Get current ring buffer count.
---获取当前缓冲区记录数。
---@return number
function CastHistoryRecorder:GetCount()
    return count
end

---Reset session data.
---重置本次会话数据。
function CastHistoryRecorder:Reset()
    head = 0
    count = 0
    sessionTotal = 0
    sessionMatches = 0
    ringBuffer = {}
end

---Save history to SavedVariables (per-spec, last SAVE_CAPACITY).
---将历史保存到 SavedVariables（按专精，最多SAVE_CAPACITY条）。
function CastHistoryRecorder:SaveHistory()
    if not RA.db or not RA.db.profile then return end
    local specDetector = RA:GetModule("SpecDetector")
    local specID = specDetector and specDetector:GetSpecID() or 0
    if specID == 0 then return end

    RA.db.profile.castHistory = RA.db.profile.castHistory or {}
    local entries = RingRead(SAVE_CAPACITY)
    RA.db.profile.castHistory[specID] = entries
end

---Load history from SavedVariables.
---从 SavedVariables 加载历史。
function CastHistoryRecorder:LoadHistory()
    if not RA.db or not RA.db.profile or not RA.db.profile.castHistory then return end
    local specDetector = RA:GetModule("SpecDetector")
    local specID = specDetector and specDetector:GetSpecID() or 0
    if specID == 0 then return end

    local saved = RA.db.profile.castHistory[specID]
    if not saved then return end

    -- 从最旧到最新重新填入 / replay from oldest to newest
    self:Reset()
    for i = #saved, 1, -1 do
        local e = saved[i]
        if e and e.spellID then
            RingPush(e.spellID, e.timestamp or 0, false)
        end
    end
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function CastHistoryRecorder:OnInitialize()
    -- 预初始化 ring buffer slots / pre-allocate ring buffer slots
    for i = 1, RING_CAPACITY do
        ringBuffer[i] = { 0, 0, false }
    end
end

function CastHistoryRecorder:OnEnable()
    local eh = RA:GetModule("EventHandler")
    if eh then
        eh:Subscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "CastHistoryRecorder", OnSpellCastSucceeded)


        -- 战斗结束时重置精确度计数 / reset accuracy on combat end
        eh:Subscribe("PLAYER_REGEN_ENABLED", "CastHistoryRecorder", function()
            sessionTotal = 0
            sessionMatches = 0
        end)
        -- 专精切换时重新加载历史 / reload on spec change
        eh:Subscribe("ROTAASSIST_SPEC_CHANGED", "CastHistoryRecorder", function()
            RefreshRotationSpellCache()
            self:LoadHistory()
        end)
        -- 登出时保存 / save on logout
        eh:Subscribe("PLAYER_LOGOUT", "CastHistoryRecorder", function()
            self:SaveHistory()
        end)
    end

    RefreshRotationSpellCache()
    self:LoadHistory()
end

function CastHistoryRecorder:OnDisable()
    self:SaveHistory()
    local eh = RA:GetModule("EventHandler")
    if eh then eh:Unsubscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "CastHistoryRecorder") end
end
