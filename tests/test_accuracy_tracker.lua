-- tests/test_accuracy_tracker.lua
-- Unit tests for AccuracyTracker session stats and reset logic.
local helpers = require("tests.helpers")

describe("AccuracyTracker", function()
    local RA, ns, AT

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/AccuracyTracker.lua", "RotaAssist", ns)
        AT = RA:GetModule("AccuracyTracker")
    end)

    before_each(function()
        AT:Reset()
    end)

    describe("GetSessionStats", function()
        it("returns zero stats after reset", function()
            local stats = AT:GetSessionStats()
            assert.equals(0, stats.totalCasts)
            assert.equals(0, stats.blizzardMatches)
            assert.equals(0, stats.smartMatches)
            assert.equals(0, stats.blizzardAccuracy)
            assert.equals(0, stats.smartAccuracy)
            assert.is_table(stats.perPhase)
        end)
    end)

    describe("Reset", function()
        it("clears all session counters", function()
            -- Verify reset produces clean state
            AT:Reset()
            local stats = AT:GetSessionStats()
            assert.equals(0, stats.totalCasts)
            assert.equals(0, stats.blizzardMatches)
            assert.equals(0, stats.smartMatches)
        end)
    end)

    describe("GetHistoricalTrend", function()
        it("returns empty table when RA.db is nil", function()
            local saved = RA.db
            RA.db = nil
            local trend = AT:GetHistoricalTrend()
            assert.is_table(trend)
            assert.equals(0, #trend)
            RA.db = saved
        end)

        it("returns empty table when accuracyHistory does not exist", function()
            RA.db = { profile = {} }
            local trend = AT:GetHistoricalTrend()
            assert.is_table(trend)
            assert.equals(0, #trend)
        end)

        it("returns the history array when it exists", function()
            RA.db = { profile = { accuracyHistory = {
                { date = 1000, smartAccuracy = 80, blizzardAccuracy = 70 },
                { date = 999, smartAccuracy = 60, blizzardAccuracy = 50 },
            }}}
            local trend = AT:GetHistoricalTrend()
            assert.equals(2, #trend)
            assert.equals(80, trend[1].smartAccuracy)
        end)
    end)

    describe("SaveSession", function()
        it("does not crash when RA.db is nil", function()
            RA.db = nil
            assert.has_no.errors(function()
                AT:SaveSession()
            end)
        end)

        it("does not save a session with zero casts", function()
            RA.db = { profile = { accuracyHistory = {} } }
            -- sessionActive is false after Reset, so SaveSession should early-return
            AT:SaveSession()
            assert.equals(0, #RA.db.profile.accuracyHistory)
        end)
    end)

    describe("PrintHistory", function()
        it("does not crash when RA.db is nil", function()
            RA.db = nil
            assert.has_no.errors(function()
                AT:PrintHistory()
            end)
        end)

        it("prints 'No records yet' when history is empty", function()
            RA.db = { profile = { accuracyHistory = {} } }
            -- Clear previous messages
            DEFAULT_CHAT_FRAME._messages = {}
            AT:PrintHistory()
            -- Should have printed header + "No records yet" + footer
            local found = false
            for _, msg in ipairs(DEFAULT_CHAT_FRAME._messages) do
                if msg:find("No records yet") then found = true end
            end
            assert.is_true(found)
        end)
    end)
end)
