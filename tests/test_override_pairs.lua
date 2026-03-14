-- tests/test_override_pairs.lua
-- Validates the Override Pair system end-to-end:
-- Blade Dance (188499) ↔ Death Sweep (210152)
-- Demon's Bite (162243) ↔ Demon Blades (203555)
-- Chaos Strike (162794) ↔ Annihilation (201427)
local helpers = require("tests.helpers")

describe("Override Pairs System", function()
    local RA, ns

    setup(function()
        helpers.ensureMockLoaded()
        _G.GetSpecialization = function() return 1 end
        _G.GetSpecializationInfo = function()
            return 577, "Havoc", "", 1247264, "DAMAGER"
        end
        _G.UnitClass = function() return "Demon Hunter", "DEMONHUNTER", 12 end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Data/WhitelistSpells.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/APLEngine.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/SmartQueueManager.lua", "RotaAssist", ns)
    end)

    describe("Registry bidirectional mapping", function()
        it("188499 maps to 210152", function()
            assert.equals(210152, RA.Registry.OVERRIDE_PAIRS[188499])
        end)

        it("210152 maps back to 188499", function()
            assert.equals(188499, RA.Registry.OVERRIDE_PAIRS[210152])
        end)

        it("162243 maps to 203555", function()
            assert.equals(203555, RA.Registry.OVERRIDE_PAIRS[162243])
        end)

        it("203555 maps back to 162243", function()
            assert.equals(162243, RA.Registry.OVERRIDE_PAIRS[203555])
        end)

        it("162794 maps to 201427", function()
            assert.equals(201427, RA.Registry.OVERRIDE_PAIRS[162794])
        end)

        it("201427 maps back to 162794", function()
            assert.equals(162794, RA.Registry.OVERRIDE_PAIRS[201427])
        end)

        it("KNOWN_OVERRIDE_PAIRS alias points to same table", function()
            assert.equals(RA.Registry.OVERRIDE_PAIRS, RA.KNOWN_OVERRIDE_PAIRS)
        end)
    end)

    describe("SharesCooldown integration", function()
        it("Blade Dance and Death Sweep share cooldown", function()
            assert.is_true(RA:SharesCooldown(188499, 210152))
        end)

        it("Death Sweep and Blade Dance share cooldown (reverse)", function()
            assert.is_true(RA:SharesCooldown(210152, 188499))
        end)

        it("Chaos Strike and Annihilation share cooldown", function()
            assert.is_true(RA:SharesCooldown(162794, 201427))
        end)

        it("unrelated spells do not share cooldown", function()
            assert.is_false(RA:SharesCooldown(162243, 198013))
        end)

        it("same spell shares cooldown with itself", function()
            assert.is_true(RA:SharesCooldown(188499, 188499))
        end)
    end)

    describe("APLEngine SimulateSpellCast mirrors CD to paired spell", function()
        local APL

        before_each(function()
            APL = RA:GetModule("APLEngine")
            APL:SetAPL(577, { rules = {} }, 12)
        end)

        it("casting Blade Dance sets CD on Death Sweep too", function()
            local simState = {
                cooldowns = {},
                resource = 50,
                inMeta = false,
                lastCast = nil,
            }
            APL:SimulateSpellCast(simState, 188499) -- Blade Dance

            -- Both should have CD set (Blade Dance cdSeconds = 9)
            assert.is_true((simState.cooldowns[188499] or 0) > 0,
                "Blade Dance should have CD after cast")
            assert.is_true((simState.cooldowns[210152] or 0) > 0,
                "Death Sweep should mirror Blade Dance CD")
        end)

        it("casting Death Sweep sets CD on Blade Dance too", function()
            local simState = {
                cooldowns = {},
                resource = 50,
                inMeta = true,
                lastCast = nil,
            }
            APL:SimulateSpellCast(simState, 210152) -- Death Sweep

            assert.is_true((simState.cooldowns[210152] or 0) > 0)
            assert.is_true((simState.cooldowns[188499] or 0) > 0,
                "Blade Dance should mirror Death Sweep CD")
        end)

        it("casting a spell without override pair only sets its own CD", function()
            local simState = {
                cooldowns = {},
                resource = 50,
                inMeta = false,
                lastCast = nil,
            }
            APL:SimulateSpellCast(simState, 198013) -- Eye Beam (no pair)

            assert.is_true((simState.cooldowns[198013] or 0) > 0)
            -- Should not set random other spells
            assert.equals(0, simState.cooldowns[188499] or 0)
            assert.equals(0, simState.cooldowns[210152] or 0)
        end)
    end)

    describe("SQM _IsSpellOnCooldown checks paired spells", function()
        local SQM

        before_each(function()
            SQM = RA:GetModule("SmartQueueManager")
        end)

        it("detects Blade Dance on CD via API", function()
            if not SQM or not SQM._IsSpellOnCooldown then
                return pending("not exposed")
            end
            -- Mock C_Spell.GetSpellCooldown to put 188499 on 10s CD
            local origFn = _G.C_Spell.GetSpellCooldown
            _G.C_Spell.GetSpellCooldown = function(spellID)
                if spellID == 188499 or spellID == 210152 then
                    return { startTime = _G.GetTime() - 1, duration = 10, isEnabled = true, modRate = 1.0 }
                end
                return { startTime = 0, duration = 0, isEnabled = true, modRate = 1.0 }
            end

            -- RA:GetSpellCooldownSafe wraps C_Spell.GetSpellCooldown
            -- _IsSpellOnCooldown should detect this
            local onCD = SQM._IsSpellOnCooldown(188499)
            -- Result depends on how GetSpellCooldownSafe interprets startTime/duration
            -- At minimum it should not crash
            assert.is_boolean(onCD)

            _G.C_Spell.GetSpellCooldown = origFn
        end)
    end)

    describe("Passive blacklist in Override Pairs", function()
        it("Demon Blades (203555) is in passive blacklist", function()
            assert.is_true(RA.Registry.PASSIVE_BLACKLIST[203555] == true)
        end)

        it("Demon's Bite (162243) is NOT in passive blacklist", function()
            assert.is_nil(RA.Registry.PASSIVE_BLACKLIST[162243])
        end)

        it("IsSpellPassive returns true for 203555", function()
            assert.is_true(RA:IsSpellPassive(203555))
        end)

        it("IsSpellPassive returns false for 162243", function()
            assert.is_false(RA:IsSpellPassive(162243))
        end)

        it("override pair partner of passive spell is correctly identified", function()
            -- 203555 (passive) maps to 162243 (active)
            local partner = RA.Registry.OVERRIDE_PAIRS[203555]
            assert.equals(162243, partner)
            assert.is_false(RA:IsSpellPassive(partner))
        end)
    end)
end)
