-- RotaAssist Luacheck Configuration
std = "lua51"
max_line_length = 160

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
    "C_AssistedCombat", "C_Spell", "C_Timer", "C_AddOns",
    "C_CurveUtil", "CreateColor",
    "GetTime", "GetCVar", "InCombatLockdown",
    "UnitExists", "UnitCanAttack", "UnitIsDead",
    "UnitHealth", "UnitHealthMax", "UnitHealthPercent",
    "UnitPower", "UnitPowerMax",
    "UnitCastingInfo", "UnitChannelInfo",
    "IsPlayerSpell", "IsSpellKnown", "IsPassiveSpell", "FindSpellOverrideByID",
    "GetActionInfo", "GetBindingKey",
    "CreateFrame", "PlaySound", "GameTooltip",
    "GetAddOnMetadata",
    "strsplit", "wipe", "issecretvalue",
    "date", "time",
    "Enum",
    "AceGUIWidgetLayoutHeap",
}

self = false

ignore = {
    "212",  -- unused argument
    "431",  -- shadowing upvalue
}

exclude_files = {
    "addon/Data/DecisionTrees/*",
    "addon/Data/TransitionMatrix/*",
    "addon/Libs/*",
}
