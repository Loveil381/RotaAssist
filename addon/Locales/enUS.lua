------------------------------------------------------------------------
-- RotaAssist - English Locale (Primary)
-- All user-facing text keys are defined here first.
-- Other locale files only override translations.
------------------------------------------------------------------------

local L = LibStub("AceLocale-3.0"):NewLocale("RotaAssist", "enUS", true)
if not L then return end

------------------------------------------------------------------------
-- General
------------------------------------------------------------------------
L["ADDON_NAME"]         = "RotaAssist"
L["STARTUP_MESSAGE"]    = "RotaAssist v%s loaded. Type /ra for help."
L["UNKNOWN_COMMAND"]    = "Unknown command: %s — Type /ra help"

------------------------------------------------------------------------
-- Slash Command Help
------------------------------------------------------------------------
L["SLASH_HELP_HEADER"]  = "RotaAssist Commands:"
L["SLASH_HELP_CONFIG"]  = "Open settings panel"
L["SLASH_HELP_TOGGLE"]  = "Toggle display on/off"
L["SLASH_HELP_LOCK"]    = "Lock/unlock display position"
L["SLASH_HELP_RESET"]   = "Reset all settings to defaults"
L["SLASH_HELP_DEBUG"]   = "Toggle debug mode"
L["SLASH_HELP_VERSION"] = "Show version info"

------------------------------------------------------------------------
-- Settings / Config Panel
------------------------------------------------------------------------
L["CONFIG_NOT_LOADED"]  = "Config panel is not loaded yet."
L["SETTINGS_RESET"]     = "All settings have been reset to defaults."
L["DEBUG_ENABLED"]      = "Debug mode: ON"
L["DEBUG_DISABLED"]     = "Debug mode: OFF"

-- Config panel headers
L["CONFIG_HEADER_GENERAL"]    = "General"
L["CONFIG_HEADER_DISPLAY"]    = "Display"
L["CONFIG_HEADER_COOLDOWNS"]  = "Cooldowns"
L["CONFIG_HEADER_ABOUT"]      = "About"

-- General settings
L["CONFIG_ENABLED"]           = "Enable RotaAssist"
L["CONFIG_ENABLED_DESC"]      = "Toggle the addon on or off."
L["CONFIG_LANGUAGE"]          = "Language"
L["CONFIG_LANGUAGE_DESC"]     = "Select display language (requires /reload)."
L["CONFIG_DEBUG"]             = "Debug Mode"
L["CONFIG_DEBUG_DESC"]        = "Show debug messages in chat."
L["CONFIG_MINIMAP"]           = "Show Minimap Button"
L["CONFIG_MINIMAP_DESC"]      = "Toggle the minimap icon."

-- Display settings
L["CONFIG_ICON_COUNT"]        = "Number of Icons"
L["CONFIG_ICON_COUNT_DESC"]   = "How many prediction icons to show (1-5)."
L["CONFIG_SCALE"]             = "Scale"
L["CONFIG_SCALE_DESC"]        = "Overall display scale (50% - 200%)."
L["CONFIG_ALPHA"]             = "Opacity"
L["CONFIG_ALPHA_DESC"]        = "Display opacity (10% - 100%)."
L["CONFIG_LOCK"]              = "Lock Position"
L["CONFIG_LOCK_DESC"]         = "Prevent the display from being dragged."
L["CONFIG_SHOW_OOC"]          = "Show Out of Combat"
L["CONFIG_SHOW_OOC_DESC"]     = "Keep the display visible outside combat."
L["CONFIG_FADE_OOC"]          = "Fade Out of Combat"
L["CONFIG_FADE_OOC_DESC"]     = "Reduce opacity when not in combat."
L["CONFIG_KEYBINDS"]          = "Show Keybinds"
L["CONFIG_KEYBINDS_DESC"]     = "Display keybind text on icons."
L["CONFIG_COOLDOWN_SWIRL"]    = "Show Cooldown Spiral"
L["CONFIG_COOLDOWN_SWIRL_DESC"] = "Show the cooldown sweep animation on icons."

-- Cooldown panel
L["CONFIG_CD_ENABLED"]        = "Enable Cooldown Panel"
L["CONFIG_CD_ENABLED_DESC"]   = "Show the major cooldown tracking strip."
L["CONFIG_CD_SCALE"]          = "Cooldown Panel Scale"
L["CONFIG_CD_SCALE_DESC"]     = "Scale of the cooldown tracking strip (50% - 200%)."
L["CONFIG_CD_LOCK"]           = "Lock Cooldown Panel"
L["CONFIG_CD_LOCK_DESC"]      = "Prevent the cooldown panel from being dragged."

------------------------------------------------------------------------
-- Display / UI
------------------------------------------------------------------------
L["DISPLAY_LOCKED"]           = "Display locked."
L["DISPLAY_UNLOCKED"]         = "Display unlocked. Drag to reposition."
L["DISPLAY_ENABLED"]          = "Display enabled."
L["DISPLAY_DISABLED"]         = "Display hidden."

-- Right-click context menu (MainDisplay)
L["LOCK_POSITION"]            = "Lock Position"
L["UNLOCK_POSITION"]          = "Unlock Position"
L["COMBAT_ONLY_TOOLTIP"]      = "Combat Only"
L["OPTIONS"]                  = "Options"

-- PrePull Panel (PrePullPanel widget)
L["PREPULL_CHECKLIST"]        = "Pre-Pull Checklist"
L["MISSING_ITEMS"]            = "Missing %d items"

------------------------------------------------------------------------
-- Cooldown Tracker
------------------------------------------------------------------------
L["CD_READY"]                 = "Ready"
L["CD_SECONDS"]               = "%ds"
L["CD_MINUTES"]               = "%d:%02d"

------------------------------------------------------------------------
-- Tooltips & Info
------------------------------------------------------------------------
L["TOOLTIP_SOURCE_BLIZZARD"]  = "Source: Blizzard Recommendation"
L["TOOLTIP_SOURCE_APL"]       = "Source: APL Prediction"
L["TOOLTIP_SOURCE_COOLDOWN"]  = "Source: Cooldown Ready"
L["TOOLTIP_CONFIDENCE"]       = "Confidence: %d%%"
L["TOOLTIP_KEYBIND"]          = "Keybind: %s"
L["TOOLTIP_COOLDOWN"]         = "Cooldown: %s"
L["TOOLTIP_DRAG_HINT"]        = "Left-click to drag. Right-click for options."
L["TOOLTIP_MINIMAP_LEFT"]     = "Left-click: Open settings"
L["TOOLTIP_MINIMAP_RIGHT"]    = "Right-click: Toggle display"

------------------------------------------------------------------------
-- About
------------------------------------------------------------------------
L["ABOUT_DESCRIPTION"]        = "RotaAssist is an intelligent combat assistant for WoW Midnight (12.0). A smart Hekili alternative with multi-language support."
L["ABOUT_VERSION"]            = "Version: %s"
L["ABOUT_AUTHOR"]             = "Author: RotaAssist Team"
L["ABOUT_LICENSE"]            = "License: MIT"
L["ABOUT_WEBSITE"]            = "Website: github.com/yourname/rotaassist"

------------------------------------------------------------------------
-- Spec Detection
------------------------------------------------------------------------
L["SPEC_DETECTED"]            = "Detected: %s %s (%s)"
L["SPEC_NO_APL"]              = "No APL data found for your specialization."
L["SPEC_APL_LOADED"]          = "APL loaded for %s."

------------------------------------------------------------------------
-- Demon Hunter
------------------------------------------------------------------------
-- Specs
L["spec_havoc"]               = "Havoc"
L["spec_vengeance"]           = "Vengeance"
L["spec_devourer"]            = "Devourer"

-- Hero Talents
L["hero_aldrachi_reaver"]     = "Aldrachi Reaver"
L["hero_fel_scarred"]         = "Fel-Scarred"
L["hero_annihilator"]         = "Annihilator"
L["hero_void_scarred"]        = "Void-Scarred"

-- Abilities
L["EYE_BEAM"]                 = "Eye Beam"
L["BLADE_DANCE"]              = "Blade Dance"
L["DEATH_SWEEP"]              = "Death Sweep"
L["METAMORPHOSIS"]            = "Metamorphosis"
L["THE_HUNT"]                 = "The Hunt"
L["VENGEFUL_RETREAT"]         = "Vengeful Retreat"
L["ESSENCE_BREAK"]            = "Essence Break"
L["GLAIVE_TEMPEST"]           = "Glaive Tempest"
L["IMMOLATION_AURA"]          = "Immolation Aura"
L["FELBLADE"]                 = "Felblade"
L["FEL_RUSH"]                 = "Fel Rush"
L["CHAOS_STRIKE"]             = "Chaos Strike"
L["ANNIHILATION"]             = "Annihilation"
L["FIERY_BRAND"]              = "Fiery Brand"
L["FEL_DEVASTATION"]          = "Fel Devastation"
L["SPIRIT_BOMB"]              = "Spirit Bomb"
L["SOUL_CARVER"]              = "Soul Carver"
L["SIGIL_OF_FLAME"]           = "Sigil of Flame"
L["FRACTURE"]                 = "Fracture"
L["SHEAR"]                    = "Shear"
L["VOID_METAMORPHOSIS"]       = "Void Metamorphosis"
L["VOID_RAY"]                 = "Void Ray"
L["COLLAPSING_STAR"]          = "Collapsing Star"
L["CONSUME"]                  = "Consume"
L["DEVOUR"]                   = "Devour"
L["REAP"]                     = "Reap"
L["CULL"]                     = "Cull"
L["VOIDBLADE"]                = "Voidblade"
L["SOUL_IMMOLATION"]          = "Soul Immolation"
L["SHIFT"]                    = "Shift"

-- Hints
L["HINT_EYE_BEAM_DEMONIC"]    = "Use Eye Beam to enter Demonic form"
L["HINT_VOID_RAY_FURY"]       = "Void Ray at 100 Fury"
L["HINT_COLLAPSING_STAR"]     = "Collapsing Star when 30+ Souls"
L["HINT_REAP_STACKS"]         = "Reap at 3 Voidfall stacks"

------------------------------------------------------------------------
-- Smart AI Inference Tips
------------------------------------------------------------------------
L["BURST_SOON_POOL_RESOURCE"] = "Burst in %ds — Pool resource!"
L["BURST_READY"]              = "Ready for Burst!"
L["AOE_DETECTED"]             = "%d Targets — AoE Mode"
L["DEATH_SWEEP_NOTE"]         = "Death Sweep = Meta Blade Dance"
L["RESOURCE_CAPPING"]         = "Resource capping! Spend it!"

-- Combat Phases
L["PREPULL"]                  = "Pre-Pull"
L["OPENER"]                   = "Opener"
L["NORMAL"]                   = "Normal"
L["AOE"]                      = "AoE"
L["BURST_PREPARE"]            = "Burst Soon"
L["BURST_ACTIVE"]             = "BURST!"
L["BURST_COOLDOWN"]           = "Cooldown"
L["RESOURCE_STARVED"]         = "Low Res"
L["RESOURCE_CAP"]             = "Cap!"
L["EXECUTE"]                  = "Execute"
L["EMERGENCY"]                = "DANGER!"

-- UI Toggles & Metrics
L["SHOW_ACCURACY_METER"]      = "Show Accuracy Meter"
L["SHOW_PHASE_INDICATOR"]     = "Show Phase Indicator"
L["ACCURACY"]                 = "Accuracy"
L["BLIZZARD_ACCURACY"]        = "Blizzard Accuracy"
L["SMART_ACCURACY"]           = "Smart Accuracy"
