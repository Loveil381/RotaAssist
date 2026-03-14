-- RotaAssist WoW API Mock for busted unit tests
-- WoW 插件单元测试用 API 模拟层
-- All globals that WoW addons expect are set here on _G.

-- ============================================================
-- Table utilities (WoW builtins that may not exist in vanilla Lua)
-- ============================================================

--- wipe(t): Clear all keys in table, return it (WoW global)
function wipe(t)
    for k in pairs(t) do t[k] = nil end
    return t
end
_G.wipe = wipe

--- strsplit(delim, str, maxParts): split str by delim
function strsplit(delim, str, maxParts)
    local result = {}
    local pattern = string.format("([^%s]+)", delim)
    local count = 0
    for part in str:gmatch(pattern) do
        count = count + 1
        result[count] = part
        if maxParts and count >= maxParts then
            -- Remainder goes into last slot as-is: re-join leftover
            local consumed = table.concat(result, delim, 1, count - 1) .. delim
            result[count] = str:sub(#consumed + 1)
            break
        end
    end
    return unpack(result)
end
_G.strsplit = strsplit

-- ============================================================
-- Chat frame mock
-- ============================================================

DEFAULT_CHAT_FRAME = {
    _messages = {},
    AddMessage  = function(self, msg)
        table.insert(self._messages, msg)
    end,
}
_G.DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

-- ============================================================
-- Time / Combat state mock
-- ============================================================

--- GetTime(): returns fixed value for deterministic tests
function GetTime() return 1000.0 end
_G.GetTime = GetTime

--- InCombatLockdown(): always false in tests
function InCombatLockdown() return false end
_G.InCombatLockdown = InCombatLockdown

-- ============================================================
-- Secret value mock  (WoW 12.0 security model)
-- ============================================================

--- issecretvalue(): always false — test values are never secret
function issecretvalue(_) return false end
_G.issecretvalue = issecretvalue

-- ============================================================
-- Unit API mocks
-- ============================================================

function UnitExists(unit) return unit == "target" or unit == "player" end
function UnitCanAttack(_, unit) return unit == "target" end
function UnitIsDead(unit) return false end
function UnitHealth(unit) return (unit == "player") and 80000 or 50000 end
function UnitHealthMax(unit) return 100000 end
function UnitPower(unit, powerType) return 50 end
function UnitPowerMax(unit, powerType) return 100 end
function UnitCastingInfo(unit) return nil end
function UnitChannelInfo(unit) return nil end

_G.UnitExists     = UnitExists
_G.UnitCanAttack  = UnitCanAttack
_G.UnitIsDead     = UnitIsDead
_G.UnitHealth     = UnitHealth
_G.UnitHealthMax  = UnitHealthMax
_G.UnitPower      = UnitPower
_G.UnitPowerMax   = UnitPowerMax
_G.UnitCastingInfo = UnitCastingInfo
_G.UnitChannelInfo = UnitChannelInfo

-- ============================================================
-- Spell API mocks
-- ============================================================

function IsPlayerSpell(spellID) return true end
function IsPassiveSpell(spellID) return false end
function FindSpellOverrideByID(spellID) return spellID end
function GetActionInfo(slot) return nil end
function GetBindingKey(action) return nil end
function GetAddOnMetadata(name, key) return (key == "Version") and "test-dev" or nil end

_G.IsPlayerSpell        = IsPlayerSpell
_G.IsPassiveSpell       = IsPassiveSpell
_G.FindSpellOverrideByID = FindSpellOverrideByID
_G.GetActionInfo         = GetActionInfo
_G.GetBindingKey         = GetBindingKey
_G.GetAddOnMetadata      = GetAddOnMetadata

-- ============================================================
-- C_Spell namespace mock
-- ============================================================

C_Spell = {
    --- GetSpellCooldown: returns a ready-state (no CD) by default
    GetSpellCooldown = function(spellID)
        return { startTime = 0, duration = 0, isEnabled = true, modRate = 1.0 }
    end,
    --- IsSpellPassive: returns false by default
    IsSpellPassive = function(spellID) return false end,
    --- IsSpellUsable: returns true by default
    IsSpellUsable = function(spellID) return true, false end,
    --- GetOverrideSpell: returns same spellID (no override)
    GetOverrideSpell = function(spellID) return spellID end,
    --- GetSpellCharges: returns single-charge spell info
    GetSpellCharges = function(spellID)
        return { currentCharges = 1, maxCharges = 1,
                 cooldownStartTime = 0, cooldownDuration = 0 }
    end,
    --- GetSpellInfo: returns minimal spell info table
    GetSpellInfo = function(spellID)
        return { name = "MockSpell" .. tostring(spellID), castTime = 0 }
    end,
}
_G.C_Spell = C_Spell

-- ============================================================
-- C_AddOns namespace mock
-- ============================================================

C_AddOns = {
    GetAddOnMetadata = function(name, key)
        return (key == "Version") and "test-dev" or nil
    end,
}
_G.C_AddOns = C_AddOns

-- ============================================================
-- C_Timer namespace mock
-- ============================================================

C_Timer = {
    NewTicker = function(interval, callback, iterations)
        -- Return a mock ticker with a Cancel method
        return { Cancel = function(self) end }
    end,
    After = function(delay, callback)
        -- No-op in tests
    end,
}
_G.C_Timer = C_Timer

-- ============================================================
-- CreateFrame mock  (minimal Frame object)
-- ============================================================

local function makeFrame(frameType, name, parent, template)
    local frame = {
        _scripts   = {},
        _alpha     = 1.0,
        _shown     = true,
        _children  = {},
        _type      = frameType or "Frame",
    }

    function frame:SetScript(event, fn) self._scripts[event] = fn end
    function frame:GetScript(event) return self._scripts[event] end
    function frame:Show() self._shown = true end
    function frame:Hide() self._shown = false end
    function frame:IsShown() return self._shown end
    function frame:SetSize(w, h) self._w, self._h = w, h end
    function frame:GetSize() return self._w or 0, self._h or 0 end
    function frame:SetPoint(...) end
    function frame:ClearAllPoints() end
    function frame:SetAlpha(a) self._alpha = a end
    function frame:GetAlpha() return self._alpha end
    function frame:SetFrameStrata(s) end
    function frame:SetMovable(b) end
    function frame:EnableMouse(b) end
    function frame:RegisterForDrag(...) end
    function frame:StartMoving() end
    function frame:StopMovingOrSizing() end
    function frame:SetClampedToScreen(b) end
    function frame:SetWidth(w) self._w = w end
    function frame:SetHeight(h) self._h = h end
    function frame:GetWidth() return self._w or 0 end
    function frame:GetHeight() return self._h or 0 end
    function frame:SetText(t) self._text = t end
    function frame:GetText() return self._text or "" end
    function frame:SetTextColor(...) end
    function frame:SetFont(...) end
    function frame:SetJustifyH(j) end
    function frame:SetJustifyV(j) end
    function frame:SetTexture(t) self._texture = t end
    function frame:SetVertexColor(...) end
    function frame:SetAllPoints(parent) end
    function frame:SetMinMaxValues(min, max) self._min, self._max = min, max end
    function frame:SetValue(v) self._value = v end
    function frame:GetValue() return self._value or 0 end
    function frame:SetStatusBarTexture(t) end
    function frame:SetStatusBarColor(...) end
    function frame:CreateTexture(name, layer)
        return makeFrame("Texture", name, frame)
    end
    function frame:CreateFontString(name, layer, template)
        return makeFrame("FontString", name, frame)
    end
    function frame:RegisterEvent(event) end
    function frame:UnregisterEvent(event) end
    function frame:UnregisterAllEvents() end

    return frame
end

function CreateFrame(frameType, name, parent, template)
    return makeFrame(frameType, name, parent, template)
end
_G.CreateFrame = CreateFrame

-- ============================================================
-- Sound / UI mock
-- ============================================================

function PlaySound(soundID, channel, forceNoDuplicates) end
_G.PlaySound = PlaySound

SOUNDKIT = setmetatable({}, { __index = function(_, k) return 0 end })
_G.SOUNDKIT = SOUNDKIT

STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
_G.STANDARD_TEXT_FONT = STANDARD_TEXT_FONT

UIParent = makeFrame("Frame", "UIParent", nil)
_G.UIParent = UIParent

GameTooltip = makeFrame("GameTooltip", "GameTooltip", UIParent)
function GameTooltip:SetOwner(owner, anchor) end
function GameTooltip:AddLine(text, r, g, b) end
function GameTooltip:Show() end
function GameTooltip:Hide() end
_G.GameTooltip = GameTooltip

-- ============================================================
-- WoW Settings / Menu API mocks
-- ============================================================

Settings = {}
function Settings.RegisterCanvasLayoutCategory(...) end
function Settings.RegisterAddOnCategory(...) end
function Settings.OpenToCategory(...) end
_G.Settings = Settings

function InterfaceOptionsFrame_OpenToCategory(panel) end
_G.InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory

MenuUtil = {}
function MenuUtil.CreateContextMenu(...) end
_G.MenuUtil = MenuUtil

Enum = {}
_G.Enum = Enum

-- ============================================================
-- LibStub mock
-- ============================================================

-- Minimal AceAddon-like object that Init.lua constructs via LibStub.
-- 模拟 Ace3 LibStub，返回一个支持 NewAddon 的伪库。

local _libstub_libs = {}

local function makeAceAddon(name, ...)
    local addon = {
        name      = name,
        modules   = {},
        _enabled  = false,
        _mixins   = { ... },
    }

    -- AceEvent message system mock
    -- Stores message callbacks: _messageCallbacks[eventName] = callback
    addon._messageCallbacks = {}
    addon._eventCallbacks = {}

    function addon:RegisterChatCommand(cmd, handler) end

    function addon:RegisterMessage(eventName, callback)
        self._messageCallbacks[eventName] = callback
    end

    function addon:UnregisterMessage(eventName)
        self._messageCallbacks[eventName] = nil
    end

    function addon:SendMessage(eventName, ...)
        local cb = self._messageCallbacks[eventName]
        if cb then cb(eventName, ...) end
    end

    function addon:RegisterEvent(eventName, callback)
        self._eventCallbacks[eventName] = callback
    end

    function addon:UnregisterEvent(eventName)
        self._eventCallbacks[eventName] = nil
    end

    function addon:Print(msg)
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end

    return addon
end

local AceAddonLib = {
    NewAddon = function(self, name, ...)
        local a = makeAceAddon(name, ...)
        _libstub_libs["AceAddon:" .. name] = a
        return a
    end,
}

local AceLocaleLib = {
    GetLocale = function(self, name)
        -- Returns a table that returns the key itself for any locale lookup
        return setmetatable({}, { __index = function(_, k) return k end })
    end,
}

local AceDBLib = {
    New = function(self, svName, defaults)
        return { profile = { general = {} } }
    end,
}

_libstub_libs["AceAddon-3.0"]  = AceAddonLib
_libstub_libs["AceLocale-3.0"] = AceLocaleLib
_libstub_libs["AceDB-3.0"]     = AceDBLib
-- Stubs for other libs referenced by Init.lua slash commands
_libstub_libs["AceConfigDialog-3.0"] = { Open = function() end }

function LibStub(libName, optional)
    local lib = _libstub_libs[libName]
    if not lib and not optional then
        -- Unknown lib: return a harmless mock table so require-like calls succeed
        lib = setmetatable({}, {
            __index    = function(_, k) return function() end end,
            __newindex = function() end,
        })
    end
    return lib
end
_G.LibStub = LibStub
