-- tests/test_init_helpers.lua
-- Unit tests for Init.lua helper functions:
--   GetBaseSpellID, SharesCooldown, IsSpellRecommendable, GetPlayerHealthPercentSafe
local helpers = require("tests.helpers")

describe("Init.lua helper functions", function()
    local RA, ns

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
    end)

    -- ================================================================
    -- GetBaseSpellID
    -- ================================================================
    describe("GetBaseSpellID", function()
        it("returns the lower ID for Blade Dance (188499) / Death Sweep (210152)", function()
            assert.equals(188499, RA:GetBaseSpellID(188499))
            assert.equals(188499, RA:GetBaseSpellID(210152))
        end)

        it("returns the lower ID for Chaos Strike (162794) / Annihilation (201427)", function()
            assert.equals(162794, RA:GetBaseSpellID(162794))
            assert.equals(162794, RA:GetBaseSpellID(201427))
        end)

        it("returns the spell itself when not in an override pair", function()
            assert.equals(99999, RA:GetBaseSpellID(99999))
        end)

        it("returns nil input unchanged", function()
            assert.is_nil(RA:GetBaseSpellID(nil))
        end)
    end)

    -- ================================================================
    -- SharesCooldown
    -- ================================================================
    describe("SharesCooldown", function()
        it("returns true for the same spell", function()
            assert.is_true(RA:SharesCooldown(188499, 188499))
        end)

        it("returns true for Blade Dance ↔ Death Sweep", function()
            assert.is_true(RA:SharesCooldown(188499, 210152))
            assert.is_true(RA:SharesCooldown(210152, 188499))
        end)

        it("returns false for unrelated spells", function()
            assert.is_false(RA:SharesCooldown(188499, 162794))
        end)

        it("returns false when either argument is nil", function()
            assert.is_false(RA:SharesCooldown(nil, 188499))
            assert.is_false(RA:SharesCooldown(188499, nil))
            assert.is_false(RA:SharesCooldown(nil, nil))
        end)
    end)

    -- ================================================================
    -- IsSpellRecommendable
    -- ================================================================
    describe("IsSpellRecommendable", function()
        it("returns false for nil", function()
            assert.is_false(RA:IsSpellRecommendable(nil))
        end)

        it("returns false for 0", function()
            assert.is_false(RA:IsSpellRecommendable(0))
        end)

        it("returns false for auto-attack (6603)", function()
            assert.is_false(RA:IsSpellRecommendable(6603))
        end)

        it("returns false for a known passive (203555 Demon Blades)", function()
            assert.is_false(RA:IsSpellRecommendable(203555))
        end)

        it("returns true for a normal active spell (162243 Demon's Bite)", function()
            -- Mock: IsPlayerSpell returns true, C_Spell.IsSpellUsable returns true
            assert.is_true(RA:IsSpellRecommendable(162243))
        end)

        it("returns false when IsPlayerSpell says unlearned", function()
            local orig = _G.IsPlayerSpell
            _G.IsPlayerSpell = function(id) return id ~= 77777 end
            assert.is_false(RA:IsSpellRecommendable(77777))
            _G.IsPlayerSpell = orig
        end)

        it("returns false when C_Spell.IsSpellUsable returns false", function()
            local orig = C_Spell.IsSpellUsable
            C_Spell.IsSpellUsable = function(id) return false end
            -- Use a spell that passes all other checks
            assert.is_false(RA:IsSpellRecommendable(162243))
            C_Spell.IsSpellUsable = orig
        end)
    end)

    -- ================================================================
    -- GetPlayerHealthPercentSafe
    -- ================================================================
    describe("GetPlayerHealthPercentSafe", function()
        it("returns 0.8 with default mock (80000/100000)", function()
            assert.equals(0.8, RA:GetPlayerHealthPercentSafe())
        end)

        it("returns nil when UnitHealth returns a secret value", function()
            local orig = _G.issecretvalue
            local origHP = _G.UnitHealth
            _G.UnitHealth = function() return "SECRET" end
            _G.issecretvalue = function(v) return v == "SECRET" end
            assert.is_nil(RA:GetPlayerHealthPercentSafe())
            _G.UnitHealth = origHP
            _G.issecretvalue = orig
        end)

        it("returns nil when UnitHealthMax is 0", function()
            local orig = _G.UnitHealthMax
            _G.UnitHealthMax = function() return 0 end
            assert.is_nil(RA:GetPlayerHealthPercentSafe())
            _G.UnitHealthMax = orig
        end)
    end)
end)
