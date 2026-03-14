-- tests/test_prepull_checker.lua
-- Unit tests for addon/Engine/PrePullChecker.lua
local helpers = require("tests.helpers")

describe("PrePullChecker", function()
    local RA, ns, PPC

    setup(function()
        helpers.ensureMockLoaded()

        -- PrePullChecker uses C_UnitAuras; mock it
        _G.C_UnitAuras = _G.C_UnitAuras or {}
        _G.C_UnitAuras.GetAuraDataBySpellName = _G.C_UnitAuras.GetAuraDataBySpellName or function()
            return nil
        end
        -- Fallback aura iteration mock
        _G.UnitBuff = _G.UnitBuff or function() return nil end
        _G.UnitAura = _G.UnitAura or function() return nil end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Engine/PrePullChecker.lua", "RotaAssist", ns)
        PPC = RA:GetModule("PrePullChecker")
    end)

    describe("module registration", function()
        it("loads successfully", function()
            assert.is_not_nil(PPC)
        end)

        it("has expected public API", function()
            assert.is_function(PPC.RunChecks)
            assert.is_function(PPC.IsReady)
        end)
    end)

    describe("RunChecks", function()
        it("returns a table", function()
            _G.InCombatLockdown = function() return false end
            local results = PPC:RunChecks()
            assert.is_table(results)
        end)

        it("returns 3 check entries for the standard consumables", function()
            _G.InCombatLockdown = function() return false end
            local results = PPC:RunChecks()
            assert.equals(3, #results)
        end)

        it("each entry has name, passed, and icon fields", function()
            _G.InCombatLockdown = function() return false end
            local results = PPC:RunChecks()
            for _, entry in ipairs(results) do
                assert.is_string(entry.name)
                assert.is_boolean(entry.passed)
                assert.is_number(entry.icon)
            end
        end)

        it("returns empty or skips when in combat", function()
            _G.InCombatLockdown = function() return true end
            local results = PPC:RunChecks()
            -- Should either return empty table or skip checks
            assert.is_table(results)
            _G.InCombatLockdown = function() return false end
        end)
    end)

    describe("IsReady", function()
        it("returns a boolean", function()
            _G.InCombatLockdown = function() return false end
            local ready = PPC:IsReady()
            assert.is_boolean(ready)
        end)

        it("returns false when no buffs are active (mock returns nil)", function()
            _G.InCombatLockdown = function() return false end
            -- With our mock returning nil for all aura lookups, no buff will be found
            local ready = PPC:IsReady()
            assert.is_false(ready)
        end)

        it("returns true when all buffs are mocked as present", function()
            -- Mock C_UnitAuras to always find the buff
            local origFunc = _G.C_UnitAuras.GetAuraDataBySpellName
            _G.C_UnitAuras.GetAuraDataBySpellName = function(unit, name)
                return { name = name, duration = 3600, expirationTime = GetTime() + 3600 }
            end

            _G.InCombatLockdown = function() return false end
            local ready = PPC:IsReady()
            assert.is_true(ready)

            -- Restore
            _G.C_UnitAuras.GetAuraDataBySpellName = origFunc
        end)
    end)

    describe("lifecycle", function()
        it("OnInitialize runs without error", function()
            assert.has_no.errors(function() PPC:OnInitialize() end)
        end)

        it("OnEnable runs without error", function()
            assert.has_no.errors(function() PPC:OnEnable() end)
        end)
    end)
end)
