-- tests/test_assisted_combat_bridge.lua
-- Unit tests for AssistedCombatBridge module.
local helpers = require("tests.helpers")

describe("AssistedCombatBridge", function()
    local RA, ns, Bridge

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)

        -- Mock C_AssistedCombat before loading the bridge
        _G.C_AssistedCombat = {
            IsAvailable = function() return true end,
            GetNextCastSpell = function(flag)
                return _G._testBlizzSpell
            end,
            GetRotationSpells = function()
                return _G._testRotationSpells or {}
            end,
            GetActionSpell = function() return nil end,
        }
        _G.C_Spell.GetSpellTexture = function(id) return 134400 end
        _G.GetCVar = function(name) return "0.1" end

        helpers.loadAddonFile("addon/Engine/AssistedCombatBridge.lua", "RotaAssist", ns)
        Bridge = RA:GetModule("AssistedCombatBridge")
    end)

    before_each(function()
        _G._testBlizzSpell = nil
        _G._testRotationSpells = {}
        Bridge:InvalidateCache()
    end)

    describe("module loading", function()
        it("registers correctly", function()
            assert.is_not_nil(Bridge)
        end)
    end)

    describe("IsAvailable", function()
        it("returns true when C_AssistedCombat exists and reports available", function()
            local avail, reason = Bridge:IsAvailable()
            assert.is_true(avail)
        end)

        it("returns false when C_AssistedCombat is nil", function()
            local saved = _G.C_AssistedCombat
            _G.C_AssistedCombat = nil
            local avail, reason = Bridge:IsAvailable()
            assert.is_false(avail)
            _G.C_AssistedCombat = saved
        end)
    end)

    describe("GetCurrentRecommendation", function()
        it("returns nil when no spell is recommended", function()
            _G._testBlizzSpell = nil
            local rec = Bridge:GetCurrentRecommendation()
            assert.is_nil(rec)
        end)

        it("returns a recommendation table with spellID when Blizzard recommends", function()
            _G._testBlizzSpell = 188499
            local rec = Bridge:GetCurrentRecommendation()
            assert.is_not_nil(rec)
            assert.equals(188499, rec.spellID)
            assert.is_string(rec.name)
            assert.is_number(rec.texture)
        end)

        it("filters out passive spells", function()
            _G._testBlizzSpell = 203555 -- Demon Blades (passive)
            local rec = Bridge:GetCurrentRecommendation()
            assert.is_nil(rec)
        end)
    end)

    describe("GetPreviousRecommendation", function()
        it("returns nil initially", function()
            assert.is_nil(Bridge:GetPreviousRecommendation())
        end)

        it("returns previous rec after recommendation changes", function()
            _G._testBlizzSpell = 188499
            Bridge:GetCurrentRecommendation()

            -- Change recommendation
            _G._testBlizzSpell = 162794
            Bridge:InvalidateCache()
            Bridge:GetCurrentRecommendation()

            local prev = Bridge:GetPreviousRecommendation()
            assert.is_not_nil(prev)
            assert.equals(188499, prev.spellID)
        end)
    end)

    describe("InvalidateCache", function()
        it("forces a fresh fetch on next call", function()
            _G._testBlizzSpell = 100
            Bridge:GetCurrentRecommendation()

            _G._testBlizzSpell = 200
            -- Without invalidation, throttle would return cached value
            Bridge:InvalidateCache()
            local rec = Bridge:GetCurrentRecommendation()
            assert.is_not_nil(rec)
            assert.equals(200, rec.spellID)
        end)
    end)

    describe("GetRotationSpells", function()
        it("returns empty table when no spells", function()
            _G._testRotationSpells = {}
            local spells = Bridge:GetRotationSpells()
            assert.is_table(spells)
            assert.equals(0, #spells)
        end)

        it("returns spell IDs from C_AssistedCombat", function()
            _G._testRotationSpells = { 100, 200, 300 }
            local spells = Bridge:GetRotationSpells()
            assert.equals(3, #spells)
        end)

        it("filters passive spells from rotation list", function()
            _G._testRotationSpells = { 100, 203555, 300 } -- 203555 is passive
            local spells = Bridge:GetRotationSpells()
            assert.equals(2, #spells)
            for _, sid in ipairs(spells) do
                assert.is_not.equals(203555, sid)
            end
        end)
    end)
end)
