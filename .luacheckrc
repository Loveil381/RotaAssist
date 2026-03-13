-- RotaAssist Luacheck Configuration
std = "lua51"
max_line_length = 160

-- WoW global functions and objects
globals = {
    "RotaAssist",
    "LibStub",
    "DEFAULT_CHAT_FRAME",
    "SOUNDKIT",
    "STANDARD_TEXT_FONT",
    "UIParent",
    "Settings",
    "InterfaceOptionsFrame_OpenToCategory",
    "MenuUtil",
}

read_globals = {
    -- WoW API
    "C_AssistedCombat", "C_Spell", "C_Timer", "C_AddOns",
    "GetTime", "GetCVar", "InCombatLockdown",
    "UnitExists", "UnitCanAttack", "UnitIsDead", "UnitHealth", "UnitHealthMax",
    "UnitPower", "UnitPowerMax",
    "IsPlayerSpell", "IsPassiveSpell", "FindSpellOverrideByID",
    "GetActionInfo", "GetBindingKey",
    "CreateFrame", "PlaySound",
    "GetAddOnMetadata",
    "strsplit",
    "issecretvalue",
    "Enum",
    -- WoW Frame API
    "GameTooltip",
    -- Ace3
    "AceGUIWidgetLayoutHeap",
}

-- Ignore unused self in methods
self = false

-- Ignore some warnings for WoW addon patterns
ignore = {
    "212",  -- unused argument (common in WoW event handlers)
}

-- Exclude generated files
exclude_files = {
    "addon/Data/DecisionTrees/*",
    "addon/Data/TransitionMatrix/*",
    "addon/Libs/*",
}
