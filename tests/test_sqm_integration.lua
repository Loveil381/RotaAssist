-- tests/test_sqm_integration.lua
-- Integration tests for SmartQueueManager: IsSpellOnCooldown, IsSpellCastable,
-- GetFinalQueue, GetLastRecommendedSpellID.
local helpers = require("tests.helpers")

describe("SmartQueueManager integration", function()
    local RA, ns, SQM

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Engine/SmartQueueManager.lua", "RotaAssist", ns)
        SQM = RA:GetModule("SmartQueueManager")
    end)

    -- ================================================================
    -- Module loading
    -- ================================================================
    describe("module loading", function()
        it("registers correctly", function()
            assert.is_not_nil(SQM)
        end)

        it("exposes _CalculateScore for testing", function()
            assert.is_function(SQM._CalculateScore)
        end)

        it("exposes _IsSpellOnCooldown for testing", function()
            assert.is_function(SQM._IsSpellOnCooldown)
        end)

        it("exposes _IsSpellCastable for testing", function()
            assert.is_function(SQM._IsSpellCastable)
        end)
    end)

    -- ================================================================
    -- IsSpellOnCooldown (via _IsSpellOnCooldown)
    -- ================================================================
    describe("IsSpellOnCooldown", function()
        it("returns false for nil", function()
            assert.is_false(SQM._IsSpellOnCooldown(nil))
        end)

        it("returns false when GetSpellCooldownSafe reports ready (remaining=0)", function()
            -- Default mock: C_Spell.GetSpellCooldown returns duration=0
            assert.is_false(SQM._IsSpellOnCooldown(162243))
        end)

        it("returns true when GetSpellCooldownSafe reports >1.0s remaining", function()
            -- Temporarily mock the cooldown API to return a long CD
            local orig = C_Spell.GetSpellCooldown
            C_Spell.GetSpellCooldown = function(id)
                if id == 88888 then
                    return { startTime = 990, duration = 30, isEnabled = true }
                end
                return { startTime = 0, duration = 0, isEnabled = true }
            end
            assert.is_true(SQM._IsSpellOnCooldown(88888))
            C_Spell.GetSpellCooldown = orig
        end)
    end)

    -- ================================================================
    -- IsSpellCastable (via _IsSpellCastable)
    -- ================================================================
    describe("IsSpellCastable", function()
        it("returns false for nil", function()
            assert.is_false(SQM._IsSpellCastable(nil))
        end)

        it("returns false for 0", function()
            assert.is_false(SQM._IsSpellCastable(0))
        end)

        it("returns false for passive spells in PASSIVE_BLACKLIST", function()
            assert.is_false(SQM._IsSpellCastable(203555))
        end)

        it("returns true for a normal castable spell", function()
            -- Default mocks: IsPlayerSpell=true, IsSpellUsable=true, no CD
            assert.is_true(SQM._IsSpellCastable(162243))
        end)

        it("returns false for unlearned spells", function()
            local orig = _G.IsPlayerSpell
            _G.IsPlayerSpell = function(id) return id ~= 55555 end
            assert.is_false(SQM._IsSpellCastable(55555))
            _G.IsPlayerSpell = orig
        end)
    end)

    -- ================================================================
    -- GetFinalQueue / GetLastRecommendedSpellID
    -- ================================================================
    describe("GetFinalQueue", function()
        it("returns a table", function()
            local q = SQM:GetFinalQueue()
            assert.is_table(q)
        end)

        it("has expected fields", function()
            local q = SQM:GetFinalQueue()
            -- main can be nil when not in combat, but the field should exist
            assert.is_table(q.next)
            assert.is_table(q.cooldowns)
        end)
    end)

    describe("GetLastRecommendedSpellID", function()
        it("returns nil initially", function()
            assert.is_nil(SQM:GetLastRecommendedSpellID())
        end)
    end)

    describe("GetDisplayData", function()
        it("returns a table with expected structure", function()
            local data = SQM:GetDisplayData()
            assert.is_table(data)
            assert.is_table(data.predictions)
            assert.is_table(data.cooldowns)
        end)
    end)
end)
