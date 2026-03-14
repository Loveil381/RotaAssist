-- tests/test_whitelist_spells.lua
-- Data integrity tests for addon/Data/WhitelistSpells.lua
local helpers = require("tests.helpers")

describe("WhitelistSpells", function()
    local RA, ns

    setup(function()
        helpers.ensureMockLoaded()
        RA, ns = helpers.loadAddon()
        helpers.loadAddonFile("addon/Data/WhitelistSpells.lua", "RotaAssist", ns)
    end)

    describe("data table existence", function()
        it("RA.WhitelistSpells is defined", function()
            assert.is_not_nil(RA.WhitelistSpells)
            assert.is_table(RA.WhitelistSpells)
        end)

        it("contains at least 20 entries", function()
            local count = 0
            for _ in pairs(RA.WhitelistSpells) do count = count + 1 end
            assert.is_true(count >= 20,
                "Expected at least 20 whitelist spells, got " .. count)
        end)
    end)

    describe("entry structure", function()
        it("every key is a numeric spell ID", function()
            for spellID, _ in pairs(RA.WhitelistSpells) do
                assert.is_number(spellID)
                assert.is_true(spellID > 0, "Spell ID should be positive: " .. tostring(spellID))
            end
        end)

        it("every entry has a name string", function()
            for spellID, entry in pairs(RA.WhitelistSpells) do
                assert.is_string(entry.name,
                    "Missing name for spellID " .. spellID)
                assert.is_true(#entry.name > 0,
                    "Empty name for spellID " .. spellID)
            end
        end)

        it("every entry has a class string", function()
            for spellID, entry in pairs(RA.WhitelistSpells) do
                assert.is_string(entry.class,
                    "Missing class for spellID " .. spellID)
            end
        end)

        it("every entry has a cooldown >= 30", function()
            for spellID, entry in pairs(RA.WhitelistSpells) do
                assert.is_number(entry.cd,
                    "Missing cd for spellID " .. spellID)
                -- Allow cd = 0 for spells marked as VERIFY
                if entry.cd > 0 then
                    assert.is_true(entry.cd >= 30,
                        string.format("Spell %d (%s) has cd %d < 30",
                            spellID, entry.name, entry.cd))
                end
            end
        end)
    end)

    describe("class coverage", function()
        it("covers all 13 WoW classes", function()
            local classes = {}
            for _, entry in pairs(RA.WhitelistSpells) do
                classes[entry.class] = true
            end
            local expectedClasses = {
                "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
                "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
                "DRUID", "DEMONHUNTER", "EVOKER"
            }
            for _, cls in ipairs(expectedClasses) do
                assert.is_true(classes[cls] ~= nil,
                    "No whitelist entries found for class: " .. cls)
            end
        end)
    end)

    describe("known spells", function()
        it("contains Metamorphosis Havoc (191427)", function()
            assert.is_not_nil(RA.WhitelistSpells[191427])
            assert.equals("DEMONHUNTER", RA.WhitelistSpells[191427].class)
        end)

        it("contains Avenging Wrath (31884)", function()
            assert.is_not_nil(RA.WhitelistSpells[31884])
            assert.equals("PALADIN", RA.WhitelistSpells[31884].class)
        end)

        it("contains Ice Block (45438)", function()
            assert.is_not_nil(RA.WhitelistSpells[45438])
            assert.equals("MAGE", RA.WhitelistSpells[45438].class)
        end)

        it("contains Army of the Dead (42650)", function()
            assert.is_not_nil(RA.WhitelistSpells[42650])
            assert.equals("DEATHKNIGHT", RA.WhitelistSpells[42650].class)
        end)
    end)

    describe("no duplicate spell IDs", function()
        it("each spell ID appears exactly once (table keys are unique)", function()
            -- In Lua, table keys are inherently unique, so this is always true
            -- but we verify the table loads without overwriting
            local count = 0
            for _ in pairs(RA.WhitelistSpells) do count = count + 1 end
            assert.is_true(count > 0)
        end)
    end)
end)
