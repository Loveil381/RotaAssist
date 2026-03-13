-- tests/test_init_passive_check.lua
-- Unit tests for RA:IsSpellPassive() defined in addon/Core/Init.lua
-- 测试 Init.lua 中 IsSpellPassive 函数的核心行为。
local helpers = require("tests.helpers")

describe("RA:IsSpellPassive()", function()
    local RA, ns

    -- Fresh addon + Registry for each test group.
    -- 每个测试组前加载干净的插件和注册表。
    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
    end)

    -- --------------------------------------------------------
    -- Known passive from PASSIVE_BLACKLIST
    -- --------------------------------------------------------
    it("returns true for a known passive (203555 – Demon Blades)", function()
        assert.is_true(RA:IsSpellPassive(203555))
    end)

    it("returns true for 290271 (Demon Blades AI variant)", function()
        assert.is_true(RA:IsSpellPassive(290271))
    end)

    it("returns true for 412713 (Interwoven Threads)", function()
        assert.is_true(RA:IsSpellPassive(412713))
    end)

    -- --------------------------------------------------------
    -- Non-passive spells
    -- --------------------------------------------------------
    it("returns false for a regular castable spell (162243 – Demon's Bite)", function()
        -- C_Spell.IsSpellPassive mock returns false; not in PASSIVE_BLACKLIST
        assert.is_false(RA:IsSpellPassive(162243))
    end)

    it("returns false for spell 188499 (Blade Dance – active)", function()
        assert.is_false(RA:IsSpellPassive(188499))
    end)

    -- --------------------------------------------------------
    -- Nil / edge inputs
    -- --------------------------------------------------------
    it("returns false for nil input without crashing", function()
        assert.is_false(RA:IsSpellPassive(nil))
    end)

    it("returns false for 0 without crashing", function()
        assert.is_false(RA:IsSpellPassive(0))
    end)

    -- --------------------------------------------------------
    -- C_Spell.IsSpellPassive integration
    -- --------------------------------------------------------
    it("returns true when C_Spell.IsSpellPassive returns true for an unknown spell", function()
        -- Temporarily mock api to return true for spell 999
        local orig = C_Spell.IsSpellPassive
        C_Spell.IsSpellPassive = function(id) return id == 999 end
        local result = RA:IsSpellPassive(999)
        C_Spell.IsSpellPassive = orig
        assert.is_true(result)
    end)

    it("falls back gracefully when C_Spell.IsSpellPassive throws an error", function()
        local orig = C_Spell.IsSpellPassive
        C_Spell.IsSpellPassive = function(id) error("API unavailable") end
        -- Should NOT raise; should return false (last-resort fallback)
        assert.is_false(RA:IsSpellPassive(12345))
        C_Spell.IsSpellPassive = orig
    end)

    -- --------------------------------------------------------
    -- Resilience when Registry not loaded (RA.Registry = nil)
    -- --------------------------------------------------------
    it("does not crash and uses API fallback when RA.Registry is nil", function()
        local savedRegistry = RA.Registry
        RA.Registry = nil

        -- Should not error; should fall through to C_Spell check
        local ok, result = pcall(function()
            return RA:IsSpellPassive(162243)
        end)
        assert.is_true(ok, "IsSpellPassive should not crash with nil Registry")
        assert.is_false(result)  -- mock C_Spell returns false

        RA.Registry = savedRegistry
    end)

    it("still returns true for C_Spell passive when RA.Registry is nil", function()
        local savedRegistry = RA.Registry
        RA.Registry = nil

        local orig = C_Spell.IsSpellPassive
        C_Spell.IsSpellPassive = function(id) return id == 777 end

        local ok, result = pcall(function()
            return RA:IsSpellPassive(777)
        end)
        assert.is_true(ok)
        assert.is_true(result)

        C_Spell.IsSpellPassive = orig
        RA.Registry = savedRegistry
    end)
end)
