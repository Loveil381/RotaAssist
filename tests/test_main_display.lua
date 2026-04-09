local helpers = require("tests.helpers")

describe("MainDisplay", function()
    local RA, ns, EH, MainDisplay
    local created
    local queueData

    local function makeWidget(name)
        local widget = {
            frame = CreateFrame("Frame", name, UIParent),
            cooldownCalls = {},
        }

        function widget:SetSpell(spellID, texture)
            self.spellID = spellID
            self.texture = texture
        end

        function widget:SetCooldown(start, duration)
            self.lastCooldown = { start = start, duration = duration }
            self.cooldownCalls[#self.cooldownCalls + 1] = self.lastCooldown
        end

        function widget:SetKeybind(text)
            self.keybind = text
        end

        function widget:SetConfidence(level)
            self.confidence = level
        end

        function widget:SetGlow(enabled)
            self.glow = enabled
        end

        function widget:SetAlert(enabled)
            self.alert = enabled
        end

        function widget:SetDesaturated(enabled)
            self.desaturated = enabled
        end

        function widget:Clear()
            self.spellID = nil
            self.lastCooldown = nil
        end

        return widget
    end

    local function installUIStubs()
        created = {
            main = nil,
            interrupt = nil,
            predictions = {},
        }

        RA.UI = RA.UI or {}

        RA.UI.IconWidget = {
            Create = function(_, parent, size, name)
                local widget = makeWidget(name)
                if name == "RA_MainIcon" then
                    created.main = widget
                elseif name == "RA_InterruptIcon" then
                    created.interrupt = widget
                elseif size == 32 then
                    created.predictions[#created.predictions + 1] = widget
                end
                return widget
            end,
        }

        RA.UI.PhaseIndicator = {
            Create = function()
                return {
                    frame = CreateFrame("Frame", nil, UIParent),
                    Update = function() end,
                    Hide = function(self) self.frame:Hide() end,
                }
            end,
        }

        RA.UI.CooldownBar = {
            Create = function()
                return {
                    frame = CreateFrame("Frame", nil, UIParent),
                    Update = function(self, data) self.lastData = data end,
                }
            end,
        }

        RA.UI.DefensiveAlert = {
            Create = function()
                return {
                    iconWidget = { frame = CreateFrame("Frame", nil, UIParent) },
                    Trigger = function() end,
                    Dismiss = function() end,
                }
            end,
        }

        RA.UI.ResourceBar = {
            Create = function()
                return {
                    bg = CreateFrame("Frame", nil, UIParent),
                    UpdateSecretSafe = function() end,
                }
            end,
        }

        RA.UI.AccuracyMeter = {
            Create = function()
                return {
                    frame = CreateFrame("Frame", nil, UIParent),
                    Update = function() end,
                    Show = function(self) self.frame:Show() end,
                    Hide = function(self) self.frame:Hide() end,
                }
            end,
        }

        RA.UI.PrePullPanel = {
            Create = function()
                return {
                    frame = CreateFrame("Frame", nil, UIParent),
                    Update = function(self) self.frame:Show() end,
                    Hide = function(self) self.frame:Hide() end,
                }
            end,
        }
    end

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/UI/MainDisplay.lua", "RotaAssist", ns)

        EH = RA:GetModule("EventHandler")
        MainDisplay = RA:GetModule("MainDisplay")
        assert.is_not_nil(EH)
        assert.is_not_nil(MainDisplay)
    end)

    before_each(function()
        RA.L = setmetatable({}, { __index = function(_, key) return key end })
        RA.db = {
            profile = {
                general = {
                    enabled = true,
                },
                display = {
                    scale = 1.0,
                    alpha = 1.0,
                    locked = true,
                    hideBackground = true,
                    showOutOfCombat = true,
                    fadeOutOfCombat = false,
                    showKeybinds = true,
                    showCooldownSwirl = true,
                },
                coach = {
                    enabled = false,
                },
                accuracy = {
                    enabled = false,
                },
            },
        }

        installUIStubs()

        queueData = {
            main = { spellID = 198013, source = "BLIZZARD" },
            next = {
                { spellID = 258860, confidence = 0.85 },
                { spellID = 188499, confidence = 0.7 },
            },
            cooldowns = {},
        }

        RA.modules["SmartQueueManager"] = {
            GetFinalQueue = function()
                return queueData
            end,
        }

        RA.GetSpellCooldownSafe = function(_, spellID)
            if spellID == 198013 then
                return 5, false, 100, 30
            end
            if spellID == 258860 then
                return 3, false, 200, 10
            end
            return 0, true, 0, 0
        end

        if EH.OnEnable then
            pcall(EH.OnEnable, EH)
        end
        if MainDisplay.OnInitialize then
            pcall(MainDisplay.OnInitialize, MainDisplay)
        end
        if MainDisplay.OnEnable then
            pcall(MainDisplay.OnEnable, MainDisplay)
        end
    end)

    it("shows cooldown swirls for main and predicted icons when enabled", function()
        EH:Fire("ROTAASSIST_QUEUE_UPDATED")

        assert.is_not_nil(created.main.lastCooldown)
        assert.equals(100, created.main.lastCooldown.start)
        assert.equals(30, created.main.lastCooldown.duration)

        assert.is_not_nil(created.predictions[1].lastCooldown)
        assert.equals(200, created.predictions[1].lastCooldown.start)
        assert.equals(10, created.predictions[1].lastCooldown.duration)

        assert.is_not_nil(created.predictions[2].lastCooldown)
        assert.is_nil(created.predictions[2].lastCooldown.start)
        assert.is_nil(created.predictions[2].lastCooldown.duration)
    end)

    it("clears cooldown swirls when the display option is disabled", function()
        EH:Fire("ROTAASSIST_QUEUE_UPDATED")

        RA.db.profile.display.showCooldownSwirl = false
        EH:Fire("ROTAASSIST_SETTINGS_RESET")

        assert.is_not_nil(created.main.lastCooldown)
        assert.is_nil(created.main.lastCooldown.start)
        assert.is_nil(created.main.lastCooldown.duration)

        assert.is_not_nil(created.predictions[1].lastCooldown)
        assert.is_nil(created.predictions[1].lastCooldown.start)
        assert.is_nil(created.predictions[1].lastCooldown.duration)
    end)
end)
