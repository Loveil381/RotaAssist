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
    "CreateFrame", "PlaySound", "PlaySoundFile", "GameTooltip",
    "hooksecurefunc",
    "ActionButton_ShowOverlayGlow", "ActionButton_HideOverlayGlow",
    "UIFrameFadeIn", "UIFrameFadeOut",
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
    "211",  -- unused variable
    "212",  -- unused argument (common in WoW event handlers)
    "213",  -- unused loop variable
    "311",  -- value assigned to variable is unused
    "431",  -- shadowing upvalue
    "611",  -- line contains only whitespace
    "612",  -- line contains trailing whitespace
    "613",  -- trailing whitespace in string
    "614",  -- trailing whitespace in comment
}

exclude_files = {
    "addon/Data/DecisionTrees/*",
    "addon/Data/TransitionMatrix/*",
    "addon/Libs/*",
}
