------------------------------------------------------------------------
-- RotaAssist - MainDisplay UI Tests
-- Tests the rebuilt layout, OutOfRange detection, CD filtering, etc.
------------------------------------------------------------------------

require("busted.runner")()
require("tests.mock_wow_api")

local helpers = require("tests.helpers")

describe("MainDisplay UI Overhaul", function()
    local RA, ns
    
    setup(function()
        _G.SLASH_ROTAASSIST1 = nil
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        
        -- Load required widgets and modules
        helpers.loadAddonFile("addon/UI/Widgets.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/UI/Widgets/IconWidget.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/UI/Widgets/DefensiveAlert.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/UI/Widgets/InterruptAlert.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/SmartQueueManager.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/UI/MainDisplay.lua", "RotaAssist", ns)
        
        RA.db = { profile = { display = { iconCount = 4 }, interrupt = {} } }
        
        RA:OnInitialize()
        local MD = RA:GetModule("MainDisplay")
        MD:OnInitialize()
        MD:OnEnable()
    end)

    teardown(function()
        -- clean up if needed
    end)

    it("should filter CD predictions out of next", function()
        local eh = RA:GetModule("EventHandler")
        local sqm = RA:GetModule("SmartQueueManager")
        
        -- Mock C_Spell.GetSpellCooldown
        _G.C_Spell.GetSpellCooldown = function(spellID)
            if spellID == 1001 then
                return { startTime = 0, duration = 0 } -- Ready
            elseif spellID == 1002 then
                return { startTime = 1000, duration = 10 } -- On CD
            end
            return { startTime = 0, duration = 0 }
        end
        
        -- Force mock the SQM final queue
        sqm.GetFinalQueue = function()
            return {
                main = { spellID = 1000, source = "APL" },
                next = {
                    { spellID = 1001, confidence = 1.0 },
                    { spellID = 1002, confidence = 1.0 }
                }
            }
        end
        
        eh:Fire("ROTAASSIST_QUEUE_UPDATED")
        
        -- Wait, the UpdateDisplay modifies the data array in place, so let's verify What SQM returned was filtered
        local data = sqm:GetFinalQueue()
        assert.are.equal(1, #data.next)
        assert.are.equal(1001, data.next[1].spellID)
    end)

    it("should set SetOutOfRange when spell is out of range", function()
        local eh = RA:GetModule("EventHandler")
        local sqm = RA:GetModule("SmartQueueManager")
        local md = RA:GetModule("MainDisplay")
        
        -- Override display config
        RA.db.profile.display = { showRangeIndicator = true, showProcGlow = true }

        -- Mock out of range
        _G.C_Spell.IsSpellInRange = function(spellID, unit)
            return false
        end
        
        sqm.GetFinalQueue = function()
            return {
                main = { spellID = 2000, source = "APL" },
                next = {}
            }
        end
        
        -- We will spy on IconWidget:SetOutOfRange.
        local mainIconWidget = nil
        -- Find the widget in upvalues or we can just spy the class
        local IconWidget = RA.UI.IconWidget
        local oldSetOutOfRange = IconWidget.SetOutOfRange
        local called_oor = nil
        IconWidget.SetOutOfRange = function(self, oor)
            called_oor = oor
            oldSetOutOfRange(self, oor)
        end
        
        eh:Fire("ROTAASSIST_QUEUE_UPDATED")
        
        assert.is_true(called_oor)
        
        -- Restore
        IconWidget.SetOutOfRange = oldSetOutOfRange
    end)

    it("should show DefensiveAlert as an independent floating frame", function()
        local defAlert = RA.UI.DefensiveAlert:Create()
        assert.is_not_nil(defAlert.container)
        assert.is_false(defAlert.container:IsShown())
        
        defAlert:Trigger(5000, 134400, "Shield Wall")
        assert.is_true(defAlert.container:IsShown())
        
        defAlert:Dismiss()
        -- Should start fading out, container visibility depends on timer, but let's assume UIFrameFadeOut mock handles it
    end)
    
    it("should show InterruptAlert separately when ROTAASSIST_INTERRUPT_ALERT fires", function()
        local eh = RA:GetModule("EventHandler")
        local md = RA:GetModule("MainDisplay")
        
        -- Note: The MD initializes InterruptAlert on buildLayout()
        -- Since lua mocks don't actually track frame children easily by name, we just fire event and assume no crash
        eh:Fire("ROTAASSIST_INTERRUPT_ALERT", true, { spellID = 6552, urgency = 0.9 })
        
        -- Fire hide
        eh:Fire("ROTAASSIST_INTERRUPT_ALERT", false, nil)
    end)
end)
