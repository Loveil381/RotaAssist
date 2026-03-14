-- tests/test_registry.lua
-- Unit tests for addon/Data/Registry.lua data integrity.
local helpers = require("tests.helpers")

describe("Registry data integrity", function()
    local RA, ns

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
    end)

    describe("PASSIVE_BLACKLIST", function()
        it("exists and is a table", function()
            assert.is_table(RA.Registry.PASSIVE_BLACKLIST)
        end)

        it("contains exactly 3 known passive spell IDs", function()
            local count = 0
            for _ in pairs(RA.Registry.PASSIVE_BLACKLIST) do
                count = count + 1
            end
            assert.equals(3, count)
        end)

        it("includes Demon Blades (203555)", function()
            assert.is_true(RA.Registry.PASSIVE_BLACKLIST[203555])
        end)

        it("includes Demon Blades AI variant (290271)", function()
            assert.is_true(RA.Registry.PASSIVE_BLACKLIST[290271])
        end)

        it("includes Interwoven Threads (412713)", function()
            assert.is_true(RA.Registry.PASSIVE_BLACKLIST[412713])
        end)

        it("does not include active spells like Blade Dance (188499)", function()
            assert.is_nil(RA.Registry.PASSIVE_BLACKLIST[188499])
        end)
    end)

    describe("OVERRIDE_PAIRS", function()
        it("exists and is a table", function()
            assert.is_table(RA.Registry.OVERRIDE_PAIRS)
        end)

        it("is bidirectional (every A→B has a corresponding B→A)", function()
            for spellA, spellB in pairs(RA.Registry.OVERRIDE_PAIRS) do
                assert.equals(spellA, RA.Registry.OVERRIDE_PAIRS[spellB],
                    string.format("Missing reverse mapping: %d→%d exists but %d→%d does not",
                        spellA, spellB, spellB, spellA))
            end
        end)

        it("contains the Blade Dance ↔ Death Sweep pair", function()
            assert.equals(210152, RA.Registry.OVERRIDE_PAIRS[188499])
            assert.equals(188499, RA.Registry.OVERRIDE_PAIRS[210152])
        end)

        it("contains the Demon's Bite ↔ Demon Blades pair", function()
            assert.equals(203555, RA.Registry.OVERRIDE_PAIRS[162243])
            assert.equals(162243, RA.Registry.OVERRIDE_PAIRS[203555])
        end)

        it("contains the Chaos Strike ↔ Annihilation pair", function()
            assert.equals(201427, RA.Registry.OVERRIDE_PAIRS[162794])
            assert.equals(162794, RA.Registry.OVERRIDE_PAIRS[201427])
        end)
    end)

    describe("FALLBACK_TEXTURE", function()
        it("is set to 134400 (question mark icon)", function()
            assert.equals(134400, RA.Registry.FALLBACK_TEXTURE)
        end)
    end)

    describe("KNOWN_OVERRIDE_PAIRS alias", function()
        it("is the same table reference as OVERRIDE_PAIRS", function()
            assert.equals(RA.Registry.OVERRIDE_PAIRS, RA.KNOWN_OVERRIDE_PAIRS)
        end)
    end)
end)
