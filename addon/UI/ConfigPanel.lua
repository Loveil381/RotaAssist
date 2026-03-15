------------------------------------------------------------------------
-- RotaAssist - Config Panel
-- Settings UI using AceConfig-3.0.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA
local ConfigPanel = {}
RA:RegisterModule("ConfigPanel", ConfigPanel)

------------------------------------------------------------------------
-- Options Table
------------------------------------------------------------------------

-- FIX (Issue 4): GetOptions() is called by AceConfig every time the
-- panel opens.  The "about" description used heavy ".." concat, which
-- re-allocates strings on every open.  We cache the pre-built string
-- in ConfigPanel._aboutText during OnInitialize (called once) and
-- reference it from GetOptions() thereafter.

local function GetOptions()
    local L = RA.L

    local options = {
        name = "RotaAssist",
        type = "group",
        args = {
            general = {
                name = L["CONFIG_HEADER_GENERAL"],
                type = "group",
                order = 1,
                get = function(info) return RA.db.profile.general[info[#info]] end,
                set = function(info, value) RA.db.profile.general[info[#info]] = value end,
                args = {
                    enabled = {
                        name = L["CONFIG_ENABLED"],
                        desc = L["CONFIG_ENABLED_DESC"],
                        type = "toggle",
                        order = 10,
                    },
                    debugMode = {
                        name = L["CONFIG_DEBUG"],
                        desc = L["CONFIG_DEBUG_DESC"],
                        type = "toggle",
                        order = 20,
                        set = function(info, value)
                            RA.db.profile.general.debugMode = value
                            RA.debugMode = value
                        end,
                    },
                    minimapButton = {
                        name = L["CONFIG_MINIMAP"],
                        desc = L["CONFIG_MINIMAP_DESC"],
                        type = "toggle",
                        order = 30,
                        set = function(info, value)
                            RA.db.profile.general.minimapButton = value
                            local minimap = RA:GetModule("MinimapButton")
                            if minimap then
                                minimap:SetShown(value)
                            end
                        end,
                    },
                },
            },
            display = {
                name = L["CONFIG_HEADER_DISPLAY"],
                type = "group",
                order = 2,
                get = function(info) return RA.db.profile.display[info[#info]] end,
                set = function(info, value) RA.db.profile.display[info[#info]] = value end,
                args = {
                    iconCount = {
                        name = L["CONFIG_ICON_COUNT"] or "Icon Count",
                        desc = L["CONFIG_ICON_COUNT_DESC"] or "Number of icons to display",
                        type = "range",
                        min = 1, max = 5, step = 1,
                        order = 10,
                    },
                    iconSpacing = {
                        name = L["CONFIG_ICON_SPACING"] or "Icon Spacing",
                        desc = L["CONFIG_ICON_SPACING_DESC"] or "Spacing between icons in pixels",
                        type = "range",
                        min = 0, max = 16, step = 1,
                        order = 15,
                    },
                    scale = {
                        name = L["CONFIG_SCALE"],
                        desc = L["CONFIG_SCALE_DESC"],
                        type = "range",
                        min = 0.5, max = 2.0, step = 0.1,
                        isPercent = true,
                        order = 20,
                    },
                    alpha = {
                        name = L["CONFIG_ALPHA"],
                        desc = L["CONFIG_ALPHA_DESC"],
                        type = "range",
                        min = 0.1, max = 1.0, step = 0.05,
                        isPercent = true,
                        order = 30,
                    },
                    locked = {
                        name = L["CONFIG_LOCK"],
                        desc = L["CONFIG_LOCK_DESC"],
                        type = "toggle",
                        order = 40,
                    },
                    showOutOfCombat = {
                        name = L["CONFIG_SHOW_OOC"],
                        desc = L["CONFIG_SHOW_OOC_DESC"],
                        type = "toggle",
                        order = 50,
                    },
                    fadeOutOfCombat = {
                        name = L["CONFIG_FADE_OOC"],
                        desc = L["CONFIG_FADE_OOC_DESC"],
                        type = "toggle",
                        order = 60,
                    },
                    showKeybinds = {
                        name = L["CONFIG_KEYBINDS"],
                        desc = L["CONFIG_KEYBINDS_DESC"],
                        type = "toggle",
                        order = 70,
                    },
                    showCooldownSwirl = {
                        name = L["CONFIG_COOLDOWN_SWIRL"],
                        desc = L["CONFIG_COOLDOWN_SWIRL_DESC"],
                        type = "toggle",
                        order = 80,
                    },
                    showRangeIndicator = {
                        name = L["CONFIG_SHOW_RANGE"] or "Show Range Indicator",
                        desc = L["CONFIG_SHOW_RANGE_DESC"] or "Pulse the main icon red if the target is out of range",
                        type = "toggle",
                        order = 90,
                    },
                    showProcGlow = {
                        name = L["CONFIG_SHOW_PROC"] or "Show Proc Glow",
                        desc = L["CONFIG_SHOW_PROC_DESC"] or "Show glowing border for procs",
                        type = "toggle",
                        order = 100,
                    },
                },
            },
            cooldowns = {
                name = L["CONFIG_HEADER_COOLDOWNS"],
                type = "group",
                order = 3,
                get = function(info) return RA.db.profile.cooldowns[info[#info]] end,
                set = function(info, value) RA.db.profile.cooldowns[info[#info]] = value end,
                args = {
                    showPanel = {
                        name = L["CONFIG_CD_ENABLED"],
                        desc = L["CONFIG_CD_ENABLED_DESC"],
                        type = "toggle",
                        order = 10,
                    },
                    panelScale = {
                        name = L["CONFIG_CD_SCALE"],
                        desc = L["CONFIG_CD_SCALE_DESC"],  -- FIX: was incorrectly L["CONFIG_CD_SCALE"]
                        type = "range",
                        min = 0.5, max = 2.0, step = 0.1,
                        isPercent = true,
                        order = 20,
                    },
                    panelLocked = {
                        name = L["CONFIG_CD_LOCK"],
                        desc = L["CONFIG_CD_LOCK_DESC"],   -- FIX: was incorrectly L["CONFIG_CD_LOCK"]
                        type = "toggle",
                        order = 30,
                    },
                },
            },
            about = {
                name = L["CONFIG_HEADER_ABOUT"],
                type = "group",
                order = 4,
                args = {
                    title = {
                        -- FIX (Issue 4): reference the pre-built string cached in OnInitialize
                        name = function() return ConfigPanel._aboutText end,
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                },
            },
        },
    }

    return options
end

------------------------------------------------------------------------
-- Module Lifecycle
------------------------------------------------------------------------

function ConfigPanel:OnInitialize()
    -- FIX (Issue 4): Build the about string ONCE here instead of on every
    -- panel open.  AceConfig calls GetOptions() each open; we avoid the
    -- repeated ".." allocations by pre-building and caching the text.
    local L = RA.L
    self._aboutText = "|cFF00CCFF" .. RA.name .. "|r\n"
        .. string.format(L["ABOUT_VERSION"], RA.version) .. "\n"
        .. L["ABOUT_AUTHOR"] .. "\n"
        .. L["ABOUT_LICENSE"] .. "\n\n"
        .. "|cFFCCCCCC" .. L["ABOUT_DESCRIPTION"] .. "|r\n\n"
        .. "|cFF7FAFFF" .. L["ABOUT_WEBSITE"] .. "|r"

    LibStub("AceConfig-3.0"):RegisterOptionsTable("RotaAssist", GetOptions)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("RotaAssist", "RotaAssist")
end

function ConfigPanel:OnEnable()
    -- Nothing
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

function ConfigPanel:Toggle()
    LibStub("AceConfigDialog-3.0"):Open("RotaAssist")
end

function ConfigPanel:Open()
    LibStub("AceConfigDialog-3.0"):Open("RotaAssist")
end

function ConfigPanel:Close()
    LibStub("AceConfigDialog-3.0"):Close("RotaAssist")
end
