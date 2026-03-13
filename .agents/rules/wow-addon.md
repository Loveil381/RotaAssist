---
activation: always_on
---

# RotaAssist — WoW Addon Workspace Rules

## Project Structure
addon/ — WoW addon (Lua 5.1) Core/ — Init, SavedVars, EventHandler Data/ — Registry, SpecInfo, APL, SpecEnhancements, DecisionTrees, TransitionMatrix Engine/ — All computation modules (15 modules) UI/ — Display + Widgets Locales/ — i18n (enUS, zhCN, jaJP) training/ — Python training pipeline (scikit-learn) companion/ — (future) Tauri v2 desktop app scripts/ — Build and release scripts


## File Naming Conventions
- Engine modules: PascalCase.lua (e.g., SmartQueueManager.lua)
- APL data: `<Class>_<Spec>.lua` (e.g., DemonHunter_Havoc.lua)
- SpecEnhancements: `<Class>.lua` (e.g., DemonHunter.lua)
- Decision Trees: `<ABBR>_<Spec>_DT.lua` (e.g., DH_Havoc_DT.lua)
- Transition Matrices: `<ABBR>_<Spec>_TM.lua` (e.g., DH_Havoc_TM.lua)

## WoW 12.0 Secret Values Quick Reference
| Data | Status | Can Use In Logic? |
|------|--------|-------------------|
| C_AssistedCombat.GetNextCastSpell() | Open | ✅ Yes |
| C_AssistedCombat.GetRotationSpells() | Open | ✅ Yes |
| Player spell cast events (UNIT_SPELLCAST_*) | Non-secret | ✅ Yes |
| Secondary resources (Soul Fragments, Combo Points) | Non-secret | ✅ Yes |
| UnitHealthMax / UnitPowerMax (player) | Non-secret | ✅ Yes |
| UnitHealthPercent / UnitPowerPercent | Secret | ❌ Display only |
| Primary resource exact values (Fury/Mana/Rage) | Secret | ❌ Display only |
| Most spell CDs / Buff details (in combat) | Secret | ❌ No |
| Whitelisted spell CDs | Non-secret | ✅ Yes |
| Combat log events | Blocked | ❌ Never |

## Architecture Rules
1. Centralized data in `Data/Registry.lua` — never duplicate PASSIVE_BLACKLIST or OVERRIDE_PAIRS
2. Module communication via EventHandler:Subscribe/Fire only
3. Engine → UI dependency is ONE-WAY (Engine fires events, UI subscribes)
4. New spells/passives → add to Registry.lua, not to individual Engine files
5. New class support → create: APL/<Class>_<Spec>.lua + SpecEnhancements/<Class>.lua + DT + TM

## Common Gotchas
- `cdSeconds` should appear ONCE per APL entry (historical bug: was duplicated)
- Always check `IsPlayerSpell()` before recommending — unlearned talents return CD=0
- Override pairs (Blade Dance ↔ Death Sweep) share cooldowns — filter BOTH
- `issecretvalue()` is a WoW 12.0 global function, not our code
