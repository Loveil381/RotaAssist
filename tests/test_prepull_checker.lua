-- tests/test_prepull_checker.lua
-- Unit tests for addon/Engine/PrePullChecker.lua
local helpers = require("tests.helpers")

describe("PrePullChecker", function()
    local RA, ns, PPC

    setup(function()
        helpers.ensureMockLoaded()

        -- PrePullChecker uses C_UnitAuras.GetBuffDataByIndex and AuraUtil
        _G.C_UnitAuras = _G.C_UnitAuras or {}
        _G.C_UnitAuras.GetBuffDataByIndex = _G.C_UnitAuras.GetBuffDataByIndex or function()
            return nil
        end
        _G.C_UnitAuras.GetAuraDataBySpellName = _G.C_UnitAuras.GetAuraDataBySpellName or function()
            return nil
        end
        _G.AuraUtil = _G.AuraUtil or {}

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

        it("returns empty when in combat", function()
            _G.InCombatLockdown = function() return true end
            local results = PPC:RunChecks()
            assert.is_table(results)
            assert.equals(0, #results)
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
            local ready = PPC:IsReady()
            assert.is_false(ready)
        end)

        it("returns true when all buffs are mocked via GetBuffDataByIndex", function()
            -- hasAura iterates C_UnitAuras.GetBuffDataByIndex("player", i)
            -- and checks data.spellId. Mock it to return all 3 consumable buff IDs.
            local buffList = {
                { spellId = 104273, name = "Well Fed" },
                { spellId = 428484, name = "Flask" },
                { spellId = 270058, name = "Augment Rune" },
            }

            local origGetBuff = _G.C_UnitAuras.GetBuffDataByIndex
            _G.C_UnitAuras.GetBuffDataByIndex = function(unit, index)
                if buffList[index] then
                    return buffList[index]
                end
                return nil
            end

            _G.InCombatLockdown = function() return false end
            local ready = PPC:IsReady()
            assert.is_true(ready)

            _G.C_UnitAuras.GetBuffDataByIndex = origGetBuff
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
