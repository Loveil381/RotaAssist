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
    -- Blizzard C_ namespaces
    "C_AssistedCombat", "C_Spell", "C_Timer", "C_AddOns",
    "C_CurveUtil", "C_UnitAuras", "C_NamePlate",

    -- Color / utility
    "CreateColor",

    -- Time / combat
    "GetTime", "GetCVar", "InCombatLockdown",

    -- Unit API
    "UnitExists", "UnitCanAttack", "UnitIsDead",
    "UnitHealth", "UnitHealthMax", "UnitHealthPercent",
    "UnitPower", "UnitPowerMax",
    "UnitCastingInfo", "UnitChannelInfo",
    "UnitClass",

    -- Spec / talent
    "GetSpecialization", "GetSpecializationInfo",

    -- Spell API
    "IsPlayerSpell", "IsSpellKnown", "IsPassiveSpell",
    "FindSpellOverrideByID", "GetMacroSpell",

    -- Action bar
    "GetActionInfo", "GetBindingKey",

    -- Frame / UI
    "CreateFrame", "PlaySound", "GameTooltip",
    "hooksecurefunc",
    "ActionButton_ShowOverlayGlow", "ActionButton_HideOverlayGlow",
    "AuraUtil",
    "BackdropTemplateMixin",

    -- Addon metadata
    "GetAddOnMetadata",

    -- WoW Lua extensions
    "strsplit", "wipe", "issecretvalue",
    "bit",

    -- Lua builtins that luacheck may flag in some configs
    "date", "time",

    -- Enums / misc
    "Enum",
    "AceGUIWidgetLayoutHeap",
}

self = false

ignore = {
    "212",  -- unused argument (common in WoW event handlers)
    "431",  -- shadowing upvalue
}

exclude_files = {
    "addon/Data/DecisionTrees/*",
    "addon/Data/TransitionMatrix/*",
    "addon/Libs/*",
}
