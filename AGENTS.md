# RotaAssist — Agent Instructions

## Project Overview
RotaAssist is a WoW 12.0 Midnight AI-powered rotation assistant addon.
- **Language**: Lua 5.1 (WoW addon), Python 3.11 (training pipeline)
- **Framework**: Ace3 (AceAddon, AceDB, AceEvent, AceLocale, AceTimer)
- **Architecture**: Modular (RegisterModule/GetModule pattern, event-driven)

## Critical Constraints — WoW 12.0 Secret Values
- NEVER use combat log events (COMBAT_LOG_EVENT_UNFILTERED is blocked in 12.0)
- ALWAYS wrap API calls that may return secret values with `pcall` + `issecretvalue()` check
- Player resource (Fury/Mana/Rage) exact values are SECRET in combat — use `UnitPower` only for display (StatusBar:SetValue is allowed), never for logic branching
- Secondary resources (Soul Fragments, Combo Points, Holy Power) are NON-SECRET
- CD states of whitelisted spells are non-secret; others may be secret

## Code Style
- Bilingual comments: English + Chinese (中文). Japanese (日本語) where already present.
- Use `local` for all module-level state
- Zero-allocation patterns: `wipe()` + reuse tables instead of creating new ones in hot paths
- All pcall-protected API calls, never assume WoW APIs are available
- Module lifecycle: `OnInitialize()` → `OnEnable()` → `OnDisable()`

## Build & Test
```bash
# Lint Lua code
luacheck addon/ --config .luacheckrc

# Run training pipeline test
cd training && pip install -r requirements.txt
python simc_apl_to_dataset.py --spec havoc --output /tmp/test.csv --samples 10

# Package for release
./scripts/package.sh 1.0.0
```

## Key Architecture Rules
- Data flows: Bridge → APLEngine → NeuralPredictor → SmartQueueManager → UI
- PASSIVE_BLACKLIST and OVERRIDE_PAIRS live in Data/Registry.lua — do NOT duplicate
- Per-spec data goes in Data/SpecEnhancements/<Class>.lua and Data/APL/<Class>_<Spec>.lua
- Engine modules MUST NOT directly reference UI modules
- All events go through EventHandler:Subscribe/Fire — no direct cross-module calls

## Safety Rules
- Always create a branch before modifying code
- NO git reset --hard, git checkout -- ., rm -rf
- Commit after each logical unit of work
- Push when task is complete

## Lessons Learned (Auto-Updated)

### Round 1-2 Findings
- `Predictor.lua` in `addon/Engine/` is dead code — NOT loaded by TOC, references
  deprecated modules (AssistCapture, CooldownTracker). Do not modify it; it should
  be deleted.
- SpecEnhancements schema is inconsistent: DH uses `interruptSpellID` (flat),
  Evoker/Rogue use `interruptSpell = { spellID, ... }` (nested). Always use the
  nested format going forward.
- `resource.type` vs `resource.powerType`: Both exist. Prefer `powerType`.
  SmartQueueManager already handles both via fallback.
- Every module that creates frames or C_Timer tickers MUST implement `OnDisable()`
  to clean them up.
