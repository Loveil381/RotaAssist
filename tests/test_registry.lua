-- tests/test_registry.lua
-- Unit tests for addon/Data/Registry.lua
-- 测试注册表数据结构的正确性和一致性。
local helpers = require("tests.helpers")

describe("Registry", function()
    local RA, ns

    -- Load Init.lua (creates RA) then Registry.lua before test suite.
    -- 先加载 Init.lua 创建 RA，再加载 Registry.lua 填充数据。
    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
    end)

    -- --------------------------------------------------------
    -- PASSIVE_BLACKLIST
    -- --------------------------------------------------------
    describe("PASSIVE_BLACKLIST", function()
        it("contains 203555 (Demon Blades)", function()
            assert.is_true(RA.Registry.PASSIVE_BLACKLIST[203555] == true)
        end)

        it("contains 290271 (Demon Blades AI variant)", function()
            assert.is_true(RA.Registry.PASSIVE_BLACKLIST[290271] == true)
        end)

        it("contains 412713 (Interwoven Threads)", function()
            assert.is_true(RA.Registry.PASSIVE_BLACKLIST[412713] == true)
        end)

        it("does NOT contain a random castable spell (e.g. 162243)", function()
            assert.is_nil(RA.Registry.PASSIVE_BLACKLIST[162243])
        end)
    end)

    -- --------------------------------------------------------
    -- OVERRIDE_PAIRS — bidirectionality
    -- --------------------------------------------------------
    describe("OVERRIDE_PAIRS", function()
        it("is bidirectional: pairs[a] == b implies pairs[b] == a", function()
            local pairs_map = RA.Registry.OVERRIDE_PAIRS
            for spellA, spellB in pairs(pairs_map) do
                assert.equals(spellA, pairs_map[spellB],
                    string.format("Pair %d->%d is not bidirectional", spellA, spellB))
            end
        end)

        it("Blade Dance <-> Death Sweep (188499 <-> 210152)", function()
            assert.equals(210152, RA.Registry.OVERRIDE_PAIRS[188499])
            assert.equals(188499, RA.Registry.OVERRIDE_PAIRS[210152])
        end)

        it("Demon's Bite <-> Demon Blades (162243 <-> 203555)", function()
            assert.equals(203555, RA.Registry.OVERRIDE_PAIRS[162243])
            assert.equals(162243, RA.Registry.OVERRIDE_PAIRS[203555])
        end)
    end)

    -- --------------------------------------------------------
    -- KNOWN_OVERRIDE_PAIRS alias
    -- --------------------------------------------------------
    describe("KNOWN_OVERRIDE_PAIRS", function()
        it("is an alias to the same table as OVERRIDE_PAIRS", function()
            assert.equals(RA.Registry.OVERRIDE_PAIRS, RA.KNOWN_OVERRIDE_PAIRS)
        end)

        it("shares the same bidirectional mapping", function()
            assert.equals(210152, RA.KNOWN_OVERRIDE_PAIRS[188499])
        end)
    end)

    -- --------------------------------------------------------
    -- FALLBACK_TEXTURE
    -- --------------------------------------------------------
    describe("FALLBACK_TEXTURE", function()
        it("equals 134400 (question mark icon)", function()
            assert.equals(134400, RA.Registry.FALLBACK_TEXTURE)
        end)
    end)
end)
