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
    end)

    before_each(function()
        -- Clean up subscriptions between tests
        if EH._subscribers then
            for event in pairs(EH._subscribers) do
                EH._subscribers[event] = {}
            end
        end
    end)

    describe("Subscribe and Fire", function()
        it("delivers an event to a subscribed callback", function()
            local received = nil
            EH:Subscribe("TEST_EVENT", "TestModule", function(payload)
                received = payload
            end)
            EH:Fire("TEST_EVENT", "hello")
            assert.equals("hello", received)
        end)

        it("delivers events to multiple subscribers", function()
            local results = {}
            EH:Subscribe("MULTI_EVENT", "ModA", function(val)
                results[#results + 1] = "A:" .. tostring(val)
            end)
            EH:Subscribe("MULTI_EVENT", "ModB", function(val)
                results[#results + 1] = "B:" .. tostring(val)
            end)
            EH:Fire("MULTI_EVENT", 42)
            assert.equals(2, #results)
        end)

        it("does not deliver events after unsubscribe", function()
            local count = 0
            EH:Subscribe("UNSUB_EVENT", "Counter", function()
                count = count + 1
            end)
            EH:Fire("UNSUB_EVENT")
            assert.equals(1, count)

            EH:Unsubscribe("UNSUB_EVENT", "Counter")
            EH:Fire("UNSUB_EVENT")
            assert.equals(1, count)
        end)

        it("silently ignores firing an event with no subscribers", function()
            assert.has_no.errors(function()
                EH:Fire("NO_SUBSCRIBERS_EVENT", "data")
            end)
        end)
    end)

    describe("Duplicate subscription prevention", function()
        it("does not add the same module twice for the same event", function()
            local count = 0
            local fn = function() count = count + 1 end
            EH:Subscribe("DUP_EVENT", "SameModule", fn)
            EH:Subscribe("DUP_EVENT", "SameModule", fn)
            EH:Fire("DUP_EVENT")
            assert.equals(1, count)
        end)
    end)

    describe("UnsubscribeAll", function()
        it("removes all subscriptions for a given module", function()
            local count = 0
            EH:Subscribe("EVT_A", "Cleanup", function() count = count + 1 end)
            EH:Subscribe("EVT_B", "Cleanup", function() count = count + 1 end)
            EH:UnsubscribeAll("Cleanup")
            EH:Fire("EVT_A")
            EH:Fire("EVT_B")
            assert.equals(0, count)
        end)
    end)
end)
