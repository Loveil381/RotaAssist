-- tests/test_event_handler.lua
-- Unit tests for addon/Core/EventHandler.lua subscribe/fire/unsubscribe.
local helpers = require("tests.helpers")

describe("EventHandler", function()
    local RA, ns, EH

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        EH = RA:GetModule("EventHandler")
        assert(EH, "EventHandler module failed to load")
    end)

    -- Since the internal subscribers table is local, we cannot wipe it
    -- directly. Instead we unsubscribe known test modules after each test.
    after_each(function()
        local testModules = {
            "TestModule", "ModA", "ModB", "Counter",
            "SameModule", "Cleanup",
        }
        for _, modName in ipairs(testModules) do
            pcall(function() EH:UnsubscribeAll(modName) end)
        end
    end)

    describe("Subscribe and Fire", function()
        it("delivers an event to a subscribed callback", function()
            local received = nil
            EH:Subscribe("ROTAASSIST_TEST_EVENT", "TestModule", function(evt, payload)
                received = payload
            end)
            EH:Fire("ROTAASSIST_TEST_EVENT", "hello")
            assert.equals("hello", received)
        end)

        it("delivers events to multiple subscribers", function()
            local results = {}
            EH:Subscribe("ROTAASSIST_MULTI", "ModA", function(evt, val)
                results[#results + 1] = "A:" .. tostring(val)
            end)
            EH:Subscribe("ROTAASSIST_MULTI", "ModB", function(evt, val)
                results[#results + 1] = "B:" .. tostring(val)
            end)
            EH:Fire("ROTAASSIST_MULTI", 42)
            assert.equals(2, #results)
        end)

        it("does not deliver events after unsubscribe", function()
            local count = 0
            EH:Subscribe("ROTAASSIST_UNSUB", "Counter", function()
                count = count + 1
            end)
            EH:Fire("ROTAASSIST_UNSUB")
            assert.equals(1, count)

            EH:Unsubscribe("ROTAASSIST_UNSUB", "Counter")
            EH:Fire("ROTAASSIST_UNSUB")
            assert.equals(1, count)
        end)

        it("silently handles firing an event with no subscribers", function()
            assert.has_no.errors(function()
                EH:Fire("ROTAASSIST_NOBODY_LISTENS", "data")
            end)
        end)
    end)

    describe("Duplicate subscription prevention", function()
        it("does not add the same module twice for the same event", function()
            local count = 0
            local fn = function() count = count + 1 end
            EH:Subscribe("ROTAASSIST_DUP", "SameModule", fn)
            EH:Subscribe("ROTAASSIST_DUP", "SameModule", fn)
            EH:Fire("ROTAASSIST_DUP")
            assert.equals(1, count)
        end)
    end)

    describe("UnsubscribeAll", function()
        it("removes all subscriptions for a given module", function()
            local count = 0
            EH:Subscribe("ROTAASSIST_EVT_A", "Cleanup", function() count = count + 1 end)
            EH:Subscribe("ROTAASSIST_EVT_B", "Cleanup", function() count = count + 1 end)
            EH:UnsubscribeAll("Cleanup")
            EH:Fire("ROTAASSIST_EVT_A")
            EH:Fire("ROTAASSIST_EVT_B")
            assert.equals(0, count)
        end)
    end)
end)
