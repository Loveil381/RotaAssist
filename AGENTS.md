# RotaAssist - WoW 12.0 Intelligent Combat Assistant

## Project Overview
RotaAssist is the smart Hekili alternative for WoW Midnight (12.0).
It consists of two parts:
1. **WoW Addon** (Lua/XML) - Free, open-source, in-game combat assistant display
2. **Companion App** (Python/Tauri) - Premium desktop app for AI-powered post-combat analysis

## Target Audience
- Former Hekili users (61M+ downloads) seeking a Midnight-compatible replacement
- New/casual players who need rotation guidance
- Chinese and Japanese WoW players (underserved by existing addons)

## Architecture Rules
- WoW Addon: Pure Lua 5.1 + XML, targets WoW API 12.0 (Interface: 120000)
- Companion App: Python 3.11+ backend, Tauri 2.x frontend with Svelte, ONNX Runtime for local AI
- All UI text MUST support 3 languages: enUS, zhCN, jaJP via locale system
- NEVER access restricted combat APIs (aura states, spell cooldowns outside whitelist)
- NEVER inject into game memory or automate player actions
- Read-only access to WoWCombatLog.txt is the primary external data source
- Addon communicates with Companion via SavedVariables file exchange (not network)

## Core Architecture (C_AssistedCombat Model)
Blizzard's C_AssistedCombat API (11.1.7+ / 12.0 core) is the primary data source.
The addon follows a "Blizzard decides, APL predicts ahead" model:
- **Slot 1**: Always Blizzard's recommendation via C_AssistedCombat.GetNextCastSpell()
- **Slots 2-3**: APLEngine predicts 1-2 steps ahead using pre-baked APL knowledge
- **Sidebar**: CooldownOverlay tracks major CD readiness
- **Alert**: DefensiveAdvisor warns on low HP
- **Pre-Pull**: PrePullChecker validates consumable buffs before combat

## File Structure
rotaassist/
├── addon/                        # WoW Addon (Lua/XML)
│   ├── RotaAssist.toc            # Table of Contents (Interface: 120000)
│   ├── embeds.xml                # Library embedding manifest
│   ├── Core/
│   │   ├── Init.lua              # Addon bootstrap, module registry, slash commands
│   │   ├── EventHandler.lua      # Central event dispatcher
│   │   ├── AssistCapture.lua     # Hook Blizzard Assisted Highlights glow (fallback)
│   │   ├── CooldownTracker.lua   # Track whitelisted spell cooldowns
│   │   └── SavedVars.lua         # Persistent settings with defaults & migration
│   ├── Engine/
│   │   ├── AssistedCombatBridge.lua  # C_AssistedCombat wrapper (primary data source)
│   │   ├── APLEngine.lua         # APL state-machine simulator (prediction engine)
│   │   ├── RecommendationManager.lua # Merges Bridge + APL + CDs → final list
│   │   ├── CooldownOverlay.lua   # Major CD tracking from SpecEnhancements
│   │   ├── DefensiveAdvisor.lua  # HP monitor + defensive recommendations
│   │   ├── PrePullChecker.lua    # Out-of-combat consumable checker
│   │   └── SpecDetector.lua      # Auto-detect player class/spec on swap
│   ├── UI/
│   │   ├── MainDisplay.lua       # Hekili-style icon bar (draggable, scalable)
│   │   ├── CooldownPanel.lua     # Major cooldown overview strip
│   │   ├── ConfigPanel.lua       # AceConfig-based settings UI
│   │   ├── MinimapButton.lua     # LibDBIcon minimap toggle
│   │   ├── Widgets.lua           # Shared UI helpers
│   │   └── Widgets/
│   │       ├── GlowWidget.lua    # Custom glow fallback
│   │       └── IconWidget.lua    # Spell icon display component
│   ├── Data/
│   │   ├── WhitelistSpells.lua   # Blizzard 12.0 whitelisted spell IDs
│   │   ├── SpecInfo.lua          # All class/spec metadata (id, name, role, icon)
│   │   ├── APL/                  # Per-spec APL definitions (prediction knowledge)
│   │   │   ├── DemonHunter_Havoc.lua
│   │   │   ├── DemonHunter_Vengeance.lua
│   │   │   ├── DemonHunter_Devourer.lua
│   │   │   ├── Warrior_Arms.lua
│   │   │   ├── Warrior_Fury.lua
│   │   │   ├── Mage_Fire.lua
│   │   │   └── _Template.lua     # Template for community contributors
│   │   └── SpecEnhancements/     # Per-spec CD/defensive/resource config
│   │       └── DemonHunter.lua
│   ├── Locales/
│   │   ├── enUS.lua              # English (primary - all keys defined here)
│   │   ├── zhCN.lua              # Simplified Chinese
│   │   └── jaJP.lua              # Japanese
│   └── Libs/                     # Embedded libraries (DO NOT EDIT)
│       ├── LibStub/
│       ├── AceAddon-3.0/
│       ├── AceConfig-3.0/
│       ├── AceDB-3.0/
│       ├── AceLocale-3.0/
│       └── LibDBIcon-1.0/
├── companion/                    # Desktop Companion App (Phase 4)
│   ├── backend/
│   │   ├── log_parser/           # WoWCombatLog.txt streaming parser
│   │   ├── ai_engine/            # Combat analysis (ONNX + optional LLM)
│   │   ├── api/                  # FastAPI local server
│   │   └── data/                 # SimC reference data
│   ├── frontend/                 # Tauri + Svelte
│   └── locales/
├── docs/
│   ├── en/
│   │   ├── INSTALL.md            # Installation guide
│   │   ├── CONFIG.md             # Configuration reference
│   │   └── CONTRIBUTING.md       # How to add new spec APLs
│   ├── zh/
│   └── ja/
├── scripts/
│   ├── build_addon.sh            # Package addon for CurseForge
│   ├── build_release.sh          # Release packager (Linux/macOS)
│   ├── build_release.ps1         # Release packager (Windows)
│   └── export_spelldata.py       # Extract whitelist from Wowhead/SimC
├── .github/
│   ├── workflows/
│   │   └── release.yml           # Auto-package on tag push
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
├── AGENTS.md
├── README.md
├── CHANGELOG.md
├── LICENSE                       # MIT
└── .gitignore

## Code Style
- Lua: 4-space indent, PascalCase for module names, camelCase for local vars
- Python: Black + isort, type hints mandatory, Google-style docstrings
- Comments in English, user-facing strings ONLY through L["key"] locale lookups
- Every module must register via RA:RegisterModule(name, moduleTable)
- Every public API must have LuaDoc annotations (---@param, ---@return)

## Naming Conventions
- Global addon object: RotaAssist (abbreviated RA in code)
- SavedVariables key: RotaAssistDB
- Slash commands: /ra, /rotaassist
- Event prefix: ROTAASSIST_
- Frame names: RotaAssist_MainDisplay, RotaAssist_CooldownPanel, etc.

## Agent Task Guidelines
- ALWAYS read this file before starting any task
- When touching addon/ code, verify WoW 12.0 API compatibility
- When adding ANY user-facing text, add entries to ALL THREE locale files
- When modifying UI, provide before/after description or mock
- NEVER create features that read restricted combat data
- PREFER composition over inheritance in Lua modules
- TEST by ensuring no Lua errors would occur on /reload

## WoW 12.0 API Key Constraints

### C_AssistedCombat (PRIMARY — 11.1.7+/12.0 core)
- C_AssistedCombat.GetNextCastSpell([checkForVisibleButton]) → spellID
- C_AssistedCombat.GetActionSpell() → spellID
- C_AssistedCombat.GetRotationSpells() → spellIDs table
- C_AssistedCombat.IsAvailable() → isAvailable, failureReason
- Event: ASSISTED_COMBAT_ACTION_SPELL_CAST
- CVar: assistedCombatIconUpdateRate (default 0.1s)

### Combat-Safe APIs
- UnitHealth/UnitHealthMax("player")
- UnitPower/UnitPowerMax("player", powerType)
- C_Spell.GetSpellCooldown(spellID) — player's own spells
- C_Spell.GetSpellTexture(spellID)
- C_Spell.GetSpellCharges(spellID)
- GetTime()
- UnitExists, UnitCanAttack, UnitIsDead
- InCombatLockdown()

### RESTRICTED in Combat
- C_UnitAuras / UnitBuff / UnitDebuff → SECRET during combat
- COMBAT_LOG_EVENT_UNFILTERED → fires but restricted for decision logic
- Full aura scanning → only available out of combat (InCombatLockdown() == false)

### Still Working Hooks
- ActionButton_ShowOverlayGlow → WORKS (fallback data hook)
- Blizzard Assisted Highlights → WORKS (shows glow on recommended spell)
- C_Spell.GetSpellInfo() → WORKS for basic spell metadata
- GetSpecialization() / GetSpecializationInfo() → WORKS

## SEO & Marketing Context
- CurseForge description must mention: "Hekili alternative", "rotation helper", "Midnight 12.0"
- README must open with: "Looking for a Hekili replacement for WoW Midnight?"
- Supported languages prominently displayed: English, 简体中文, 日本語
