-- tests/test_init_slash.lua
-- Unit tests for RA:SlashCommand parsing.
local helpers = require("tests.helpers")

describe("RA:SlashCommand", function()
    local RA, ns

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)

        -- SlashCommand requires RA.L (locale table) and RA.db
        -- RA.L is set by OnInitialize via AceLocale mock (returns key as value)
        RA.L = setmetatable({}, { __index = function(_, k) return k end })
        RA.db = { profile = { general = { debugMode = false } } }

        -- Mock string.trim for Lua 5.1 (WoW extension not present in vanilla Lua)
        if not string.trim then
            string.trim = function(s) return s:match("^%s*(.-)%s*$") end
        end
    end)

    before_each(function()
        -- Clear chat messages
        DEFAULT_CHAT_FRAME._messages = {}
    end)

    describe("help command", function()
        it("prints help text for empty input", function()
            RA:SlashCommand("")
            assert.is_true(#DEFAULT_CHAT_FRAME._messages > 0)
        end)

        it("prints help text for 'help'", function()
            RA:SlashCommand("help")
            assert.is_true(#DEFAULT_CHAT_FRAME._messages > 0)
        end)
    end)

    describe("version command", function()
        it("prints version info", function()
            RA:SlashCommand("version")
            local found = false
            for _, msg in ipairs(DEFAULT_CHAT_FRAME._messages) do
                if msg:find("test%-dev") or msg:find("RotaAssist") then
                    found = true
                end
            end
            assert.is_true(found)
        end)

        it("also works with 'ver' alias", function()
            RA:SlashCommand("ver")
            assert.is_true(#DEFAULT_CHAT_FRAME._messages > 0)
        end)
    end)

    describe("debug command", function()
        it("toggles debugMode on", function()
            RA.db.profile.general.debugMode = false
            RA.debugMode = false
            RA:SlashCommand("debug")
            assert.is_true(RA.debugMode)
            assert.is_true(RA.db.profile.general.debugMode)
        end)

        it("toggles debugMode off", function()
            RA.db.profile.general.debugMode = true
            RA.debugMode = true
            RA:SlashCommand("debug")
            assert.is_false(RA.debugMode)
            assert.is_false(RA.db.profile.general.debugMode)
        end)
    end)

    describe("unknown command", function()
        it("prints a warning for unrecognized input", function()
            RA:SlashCommand("xyzzy")
            local found = false
            for _, msg in ipairs(DEFAULT_CHAT_FRAME._messages) do
                if msg:find("xyzzy") then found = true end
            end
            assert.is_true(found)
        end)
    end)

    describe("case insensitivity", function()
        it("handles uppercase input", function()
            RA:SlashCommand("VERSION")
            local found = false
            for _, msg in ipairs(DEFAULT_CHAT_FRAME._messages) do
                if msg:find("test%-dev") or msg:find("RotaAssist") then
                    found = true
                end
            end
            assert.is_true(found)
        end)
    end)
end)
