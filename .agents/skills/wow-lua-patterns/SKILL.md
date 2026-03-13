---
name: wow-lua-patterns
description: RotaAssist WoW addon Lua coding patterns and conventions
---

# WoW Addon Lua Patterns for RotaAssist

## Secret Value Safety
- Always wrap C_Spell, UnitHealth, UnitPower calls in `pcall`
- Always check `issecretvalue()` on numeric returns before arithmetic
- Return `nil` (not 0) when secret values are detected
- For HP threshold checks in combat, prefer C_CurveUtil approach (see DefensiveAdvisor)

## Table Allocation
- Never create tables inside OnUpdate / per-frame loops
- Use module-scope `_reuse` tables with `wipe()` at start of each frame
- Pattern: `wipe(myTable_reuse); local myTable = myTable_reuse`

## Registry Pattern
- All spell ID constants go in `Data/Registry.lua`
- Reference via `RA.Registry.PASSIVE_BLACKLIST`, `RA.Registry.OVERRIDE_PAIRS`
- Add defensive fallback: `RA.Registry and RA.Registry.X or {}`

## SpecEnhancements Schema
- `interruptSpell`: always use `{ spellID = N, name = "...", cooldown = N }`
- `resource`: always use `powerType` (not `type`) for Enum.PowerType
- `defensives`: array of `{ spellID, hpThreshold, name? }`
- `majorCooldowns`: array of `{ spellID, alertThreshold, name }`

## Module Lifecycle
- `OnInitialize`: create frames, set defaults (NO other module refs)
- `OnEnable`: acquire module refs via `RA:GetModule()`, subscribe events
- `OnDisable`: nil out module refs, unsubscribe, hide frames, cancel timers
- EVERY module that creates frames/timers MUST implement OnDisable

## Naming Conventions
- Module names: PascalCase (e.g., `SmartQueueManager`)
- Local functions: camelCase (e.g., `calculateScore`)
- Constants: UPPER_SNAKE_CASE (e.g., `THROTTLE_UPDATE`)
- Reuse tables: suffix `_reuse` (e.g., `candidates_reuse`)

## Event System
- Never use `RA:RegisterEvent()` directly — always go through EventHandler:Subscribe
- Unsubscribe everything in OnDisable
- Custom events: prefix with `ROTAASSIST_`
