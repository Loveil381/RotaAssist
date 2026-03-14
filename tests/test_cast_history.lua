-- tests/test_cast_history.lua
-- Unit tests for CastHistoryRecorder ring buffer logic.
local helpers = require("tests.helpers")

describe("CastHistoryRecorder", function()
    local RA, ns, CHR

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        -- EventHandler is needed by CastHistoryRecorder during load
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/CastHistoryRecorder.lua", "RotaAssist", ns)
        CHR = RA:GetModule("CastHistoryRecorder")
        -- Manually call OnInitialize to pre-allocate ring buffer
        CHR:OnInitialize()
    end)

    before_each(function()
        CHR:Reset()
    end)

    describe("empty state", function()
        it("GetCount returns 0 after Reset", function()
            assert.equals(0, CHR:GetCount())
        end)

        it("GetLastSpellID returns nil when empty", function()
            assert.is_nil(CHR:GetLastSpellID())
        end)

        it("GetNthLastSpellID returns 0 when empty", function()
            assert.equals(0, CHR:GetNthLastSpellID(1))
        end)

        it("GetTimeSinceLastCast returns 999 when empty", function()
            assert.equals(999, CHR:GetTimeSinceLastCast())
        end)

        it("GetRecentCasts returns empty table when empty", function()
            local casts = CHR:GetRecentCasts(5)
            assert.equals(0, #casts)
        end)
    end)

    describe("recording casts via internal API", function()
        -- We test the public API by directly manipulating the ring buffer
        -- through a simulated sequence. Since OnSpellCastSucceeded is a local
        -- function, we exercise it indirectly via the module's Reset + manual
        -- ring push approach: call the module's exported methods after
        -- ensuring the buffer is populated.

        -- Helper: record N casts using a mock event path.
        -- Since the internal OnSpellCastSucceeded filters by unit and rotation
        -- spells, we'll test the public API properties with GetRecentCasts
        -- after using a known approach: loadHistory from a fake saved table.

        it("LoadHistory populates the ring buffer from saved data", function()
            -- Mock RA.db for SavedVariables
            RA.db = { profile = { castHistory = {} } }
            -- Mock SpecDetector
            RA:RegisterModule("SpecDetector", {
                GetSpecID = function() return 577 end,
                GetCurrentSpec = function() return { specID = 577 } end,
            })

            -- Prepare saved history (oldest first in the saved array due to RingRead order)
            RA.db.profile.castHistory[577] = {
                { spellID = 100, timestamp = 990 },
                { spellID = 200, timestamp = 991 },
                { spellID = 300, timestamp = 992 },
            }

            CHR:LoadHistory()
            assert.equals(3, CHR:GetCount())
            -- After LoadHistory, the newest entry from the saved array is index 1
            -- (LoadHistory iterates #saved down to 1, pushing oldest first)
            assert.equals(100, CHR:GetLastSpellID())
        end)
    end)

    describe("GetAccuracy", function()
        it("returns 0% when no casts recorded", function()
            local acc = CHR:GetAccuracy()
            assert.equals(0, acc.total)
            assert.equals(0, acc.matches)
            assert.equals(0, acc.percentage)
        end)
    end)

    describe("Reset", function()
        it("clears all counters and buffer", function()
            -- Load some data first
            RA.db = { profile = { castHistory = {} } }
            RA.modules["SpecDetector"] = RA.modules["SpecDetector"] or {
                GetSpecID = function() return 577 end,
                GetCurrentSpec = function() return { specID = 577 } end,
            }
            RA.db.profile.castHistory[577] = {
                { spellID = 100, timestamp = 990 },
            }
            CHR:LoadHistory()
            assert.is_true(CHR:GetCount() > 0)

            CHR:Reset()
            assert.equals(0, CHR:GetCount())
            assert.is_nil(CHR:GetLastSpellID())
        end)
    end)
end)
