# Contributing to RotaAssist

## How to Add a New Spec

Adding a new class/spec requires creating data files and updating the TOC. Follow this checklist in order:

### 1. SpecEnhancements

Create `addon/Data/SpecEnhancements/<ClassName>.lua` (or add to an existing class file).

Define `RA.SpecEnhancements[specID]` with:
- `majorCooldowns` — array of `{spellID, alertThreshold, name}`
- `interruptSpell` — `{spellID, name, cooldown}`
- `defensives` — array of `{spellID, hpThreshold, name}`
- `resource` — `{type, maxBase, spellCosts}`
- `burstWindows` — `{meta = {trigger, duration, label}}`
- `prePullChecks` — food/flask/rune config
- `inferenceRules` — aoeSpells, singleTargetSpells, generators, spenders, etc.

See `addon/Data/SpecEnhancements/DemonHunter.lua` for reference.

### 2. APL Definition

Create `addon/Data/APL/<ClassName>_<SpecName>.lua`.

Use `addon/Data/APL/_Template.lua` as your starting point. Define:
- `class` — uppercase class token (e.g., `"MAGE"`)
- `specID` — numeric spec ID
- `profiles.default` — array of action rules: `{spellID, condition, priority, note}`

Conditions use string tokens: `ready`, `cd_ready`, `in_meta`, `not_in_meta`, `resource_above_X`, `resource_below_X`, `targets_above_X`, `always`.

### 3. DecisionTree

Create `addon/Data/DecisionTrees/<ClassAbbrev>_<SpecAbbrev>_DT.lua`.

Register in `RA.DecisionTreeData[specID]` with an `Evaluate(features)` function. The feature vector includes: `lastSpellID`, `secondLastSpellID`, `resource`, `targetCount`, `combatDuration`, `blizzardRecommendation`, `specID`, etc.

### 4. TransitionMatrix

Create `addon/Data/TransitionMatrix/<ClassAbbrev>_<SpecAbbrev>_TM.lua`.

Register in `RA.TransitionMatrixData[specID]` with a `matrix` table: `{[fromSpellID] = {[toSpellID] = probability}}`. These are generated from SimulationCraft logs or community data.

### 5. WhitelistSpells

Add entries to `addon/Data/WhitelistSpells.lua` for any major cooldowns (≥ 30s CD) specific to the new spec. Format: `[spellID] = {name, class, specID, cdSeconds}`.

### 6. Locale Strings

If any new user-facing strings are needed, add keys to ALL THREE locale files:
- `addon/Locales/enUS.lua` (primary — define all keys here)
- `addon/Locales/zhCN.lua`
- `addon/Locales/jaJP.lua`

### 7. Update TOC

Add the new files to `addon/RotaAssist.toc` in the correct section:
- APL files go under `# Data (MUST load before Engine)` after existing APL entries
- SpecEnhancements go after existing SpecEnhancements entries
- DecisionTrees and TransitionMatrices go after existing entries

### 8. Validate

Run `scripts/validate.sh` to check:
- Lua syntax passes `luac -p`
- No duplicate module registrations
- All TOC-listed files exist on disk
- Locale keys are complete across all three languages

## Code Style

- **Indent**: 4 spaces
- **Naming**: PascalCase for module names, camelCase for locals
- **Comments**: English, user-facing strings ONLY via `L["KEY"]`
- **Modules**: Must register via `RA:RegisterModule(name, table)`
- **LuaDoc**: All public methods need `---@param` and `---@return`
- **Events**: Use `EventHandler:Subscribe()`, never direct `RA:RegisterEvent()` for shared events

## Testing

Since this is a WoW addon, testing requires the game client. Before submitting:

1. Run `luac -p` on all modified `.lua` files
2. Verify no Lua errors on `/reload` in-game
3. Test spec detection on login and spec swap
4. Test combat flow for the target spec
5. Verify locale strings display correctly in all 3 languages
