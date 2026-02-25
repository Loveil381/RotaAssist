------------------------------------------------------------------------
-- RotaAssist - Pre-Pull Checker
-- Out-of-combat utility: checks food buff, flask, rune, etc.
-- Uses C_UnitAuras (unrestricted when InCombatLockdown() == false).
-- 戦闘外チェック: 食事バフ、フラスコ、ルーンの確認。
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local PrePullChecker = {}
RA:RegisterModule("PrePullChecker", PrePullChecker)

------------------------------------------------------------------------
-- Check Definitions
-- Each check: { name, localeKey, checkFn() → boolean }
------------------------------------------------------------------------

--- Well-known buff spell IDs for common consumable categories
local WELL_FED_SPELL = 104273   -- Generic "Well Fed" aura (covers all food)
local FLASK_AURA     = 428484   -- Midnight Flask aura (placeholder; verify on live)
local AUGMENT_RUNE   = 270058   -- Augmented Rune

---@class CheckResult
---@field name string Display name
---@field passed boolean Whether the check passed
---@field icon number|nil Texture ID for UI

---Scan player auras for a specific spellID.
---C_UnitAuras is fully available out of combat.
---@param targetSpellID number
---@return boolean found
local function hasAura(targetSpellID)
    if InCombatLockdown() then
        -- Cannot safely read auras in combat; assume pass to avoid false negatives
        return true
    end

    -- C_UnitAuras.GetAuraDataBySpellName is another option, but
    -- iterating via AuraUtil is simplest for ID lookups.
    if not AuraUtil or not AuraUtil.FindAuraByName then
        -- Fallback: iterate manually
        for i = 1, 40 do
            local auraData
            if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
                local ok, data = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
                if ok and data then
                    auraData = data
                end
            end
            if not auraData then break end
            if auraData.spellId == targetSpellID then
                return true
            end
        end
        return false
    end

    -- Use AuraUtil if available (WoW 12.0 should have it)
    local name = AuraUtil.FindAuraByName and nil  -- not reliable by name
    -- Direct approach: iterate
    for i = 1, 40 do
        local ok, data = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
        if not ok or not data then break end
        if data.spellId == targetSpellID then
            return true
        end
    end
    return false
end

------------------------------------------------------------------------
-- Checks
------------------------------------------------------------------------

local checkDefs = {
    {
        name     = "Well Fed",
        icon     = 134062,  -- food icon
        checkFn  = function() return hasAura(WELL_FED_SPELL) end,
    },
    {
        name     = "Flask Active",
        icon     = 967546,  -- flask icon
        checkFn  = function() return hasAura(FLASK_AURA) end,
    },
    {
        name     = "Augment Rune",
        icon     = 1394891, -- rune icon
        checkFn  = function() return hasAura(AUGMENT_RUNE) end,
    },
}

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

---Run all pre-pull checks and return results.
---Should only be called out of combat (InCombatLockdown() == false).
---@return CheckResult[] results Array of { name, passed, icon }
function PrePullChecker:RunChecks()
    if InCombatLockdown() then
        RA:PrintDebug("PrePullChecker: Skipped — player is in combat")
        return {}
    end

    local results = {}
    for _, def in ipairs(checkDefs) do
        local passed = false
        local ok, result = pcall(def.checkFn)
        if ok then passed = result end

        results[#results + 1] = {
            name   = def.name,
            passed = passed,
            icon   = def.icon,
        }
    end
    return results
end

---Check if all pre-pull buffs are active.
---@return boolean allPassed
function PrePullChecker:IsReady()
    local results = self:RunChecks()
    for _, r in ipairs(results) do
        if not r.passed then return false end
    end
    return true
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function PrePullChecker:OnInitialize()
    -- Nothing needed
end

function PrePullChecker:OnEnable()
    -- Nothing needed — checks are pulled on-demand
end
