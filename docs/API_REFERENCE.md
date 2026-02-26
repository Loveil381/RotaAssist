# RotaAssist API Reference

Every public method of every module, grouped by layer.

---

## Core Layer

### Init (`RA`)
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `RegisterModule(name, table)` | `string, table` | `table` | Register a module for lifecycle management |
| `GetModule(name)` | `string` | `table\|nil` | Retrieve a registered module by name |
| `Print(msg)` | `string` | — | Print to chat with addon prefix |
| `PrintDebug(msg)` | `string` | — | Print debug message (only when `debugMode=true`) |
| `PrintWarning(msg)` | `string` | — | Print yellow warning message |
| `PrintError(msg)` | `string` | — | Print red error message |
| `SlashCommand(input)` | `string` | — | Process `/ra` slash commands |

### EventHandler
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `Subscribe(eventName, moduleName, callback)` | `string, string, function` | — | Subscribe to a WoW or custom event |
| `Unsubscribe(eventName, moduleName)` | `string, string` | — | Unsubscribe from an event |
| `SubscribeMany(events, moduleName, callback)` | `string[], string, function` | — | Subscribe to multiple events |
| `UnsubscribeMany(events, moduleName)` | `string[], string` | — | Unsubscribe from multiple events |
| `UnsubscribeAll(moduleName)` | `string` | — | Remove all subscriptions for a module |
| `Fire(eventName, ...)` | `string, ...any` | — | Fire a custom `ROTAASSIST_*` event |
| `SetThrottle(eventName, interval)` | `string, number` | — | Set minimum dispatch interval |
| `ClearThrottle(eventName)` | `string` | — | Remove throttle |
| `GetSubscriptionSummary()` | — | `string` | Debug dump of all subscriptions |

### SavedVars
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `OnInitialize()` | — | — | Set up AceDB with defaults |
| `RefreshProfile()` | — | — | Re-sync settings after profile change |
| `ResetToDefaults()` | — | — | Reset all settings to factory defaults |
| `GetDefaults()` | — | `table` | Get deep copy of defaults table |

### AssistCapture
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetCurrentRecommendation()` | — | `number\|nil` | Get current glowing spell ID |
| `GetRecentHistory(count)` | `number\|nil` | `table[]` | Get recent glow history |
| `IsSpellRecommended(spellID)` | `number` | `boolean` | Check if spell is currently glowing |

### CooldownTracker
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetAllCooldowns()` | — | `table<spellID, state>` | Get all tracked cooldown states |
| `GetReadySpells()` | — | `table[]` | Get array of ready spells |
| `GetTrackedCount()` | — | `number` | Count of tracked spells |
| `IsSpellTracked(spellID)` | `number` | `boolean` | Check if spell is tracked |
| `SetEnabled(enabled)` | `boolean` | — | Enable/disable tracking |

---

## Engine Layer

### SpecDetector
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetCurrentSpec()` | — | `SpecInfo\|nil` | Get `{classID, specID, className, specName, role, classFile, icon}` |
| `IsRole(role)` | `string` | `boolean` | Check player role ("DAMAGER"/"HEALER"/"TANK") |
| `GetSpecID()` | — | `number\|nil` | Get current spec ID |
| `GetPrimaryPowerType()` | — | `number\|nil` | Get `Enum.PowerType` from SpecEnhancements |

### AssistedCombatBridge
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `IsAvailable()` | — | `boolean, string\|nil` | Check C_AssistedCombat availability |
| `GetCurrentRecommendation()` | — | `table\|nil` | Get `{spellID, texture, name}` (throttled) |
| `GetRotationSpells()` | — | `number[]` | Get full rotation spell list from Blizzard |
| `GetActionSpell()` | — | `number\|nil` | Get action spell from Blizzard |
| `OnAssistedSpellCast(callback)` | `function` | — | Register callback for assisted casts |

### APLEngine
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `SetAPL(specID, aplData, classID)` | `number, table, number` | — | Load an APL definition |
| `PredictNext(currentSpell, state, depth)` | `number\|nil, table, number` | `table[]` | Predict next N spells |
| `EvaluateCondition(condition, spellID, simState)` | `string, number, table` | `boolean` | Evaluate APL condition |
| `SimulateSpellCast(simState, spellID)` | `table, number` | `table` | Simulate a spell cast |
| `HasAPL()` | — | `boolean` | Check if APL is loaded |
| `GetCurrentAPL()` | — | `table\|nil` | Get current APL data |
| `IsMetaActive()` | — | `boolean` | Check Metamorphosis state estimate |
| `SetActiveProfile(name)` | `string` | — | Switch APL profile |
| `ClearAPL()` | — | — | Clear loaded APL |

### SmartQueueManager
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetFinalQueue()` | — | `table` | Get `{main, next[], cooldowns[], defensive, phase, tip, aiContext}` |
| `GetDisplayData()` | — | `table` | Backward-compatible display format |

### CooldownOverlay
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetCooldownStates()` | — | `table<spellID, state>` | Get `{[spellID] = {remaining, ready, texture, name}}` |
| `GetReadyCooldowns()` | — | `table[]` | Get array of ready CDs |
| `LoadForSpec(specID)` | `number\|nil` | — | Load major CD config for a spec |

### DefensiveAdvisor
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetHealthPercent()` | — | `number` | Get current HP% (0.0–1.0) |
| `GetDefensives()` | — | `table[]\|nil` | Get configured defensives for current spec |
| `GetActiveRecommendation()` | — | `table\|nil` | Get `{spellID, name, urgency, texture}` or nil |
| `LoadForSpec(specID)` | `number\|nil` | — | Load defensive config for a spec |

### CastHistoryRecorder
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetRecentCasts(n)` | `number\|nil` | `table[]` | Get last N casts (newest first) |
| `GetLastSpellID()` | — | `number\|nil` | Get most recent spell ID |
| `GetNthLastSpellID(n)` | `number` | `number` | Get Nth-to-last spell ID |
| `GetTimeSinceLastCast()` | — | `number` | Seconds since last cast |
| `GetAccuracy()` | — | `table` | Get `{total, matches, percentage}` |
| `GetCastSequenceHash(n)` | `number` | `number` | Hash of last N spell IDs |
| `GetCount()` | — | `number` | Current ring buffer count |
| `Reset()` | — | — | Reset session data |
| `SaveHistory()` | — | — | Save to SavedVariables |
| `LoadHistory()` | — | — | Load from SavedVariables |

### AccuracyTracker
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetSessionStats()` | — | `table` | Get `{totalCasts, blizzardMatches, blizzardAccuracy, smartMatches, smartAccuracy, perPhase}` |
| `GetHistoricalTrend()` | — | `table[]` | Get historical combat records |
| `Reset()` | — | — | Reset session counters |
| `SaveSession()` | — | — | Save session summary to DB |

### NeuralPredictor
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `PredictFromDecisionTree(features)` | `table` | `table\|nil` | Predict using decision tree |
| `PredictFromMarkov(lastSpellID, topN)` | `number, number\|nil` | `table[]` | Predict using Markov matrix |
| `UpdateMarkovMatrix(fromSpell, toSpell)` | `number, number` | — | Update personal transition count |
| `BuildFeatures()` | — | `table` | Build feature vector from all modules |
| `GetCombinedPrediction()` | — | `table` | Get blended DT+Markov+Blizzard prediction |
| `LoadForSpec(specID)` | `number` | — | Load DT and TM for a spec |
| `SaveMarkovMatrix()` | — | — | Persist personal matrix |
| `LoadMarkovMatrix()` | — | — | Load personal matrix |

### PatternDetector
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetPhase()` | — | `table` | Get `{phase, confidence, signals}` |
| `GetNameplateCount()` | — | `number` | Count hostile nameplates (cached) |
| `GetResourceTrend()` | — | `string` | "rising", "falling", or "stable" |

### AIInference
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetContext()` | — | `table` | Get full inferred state payload |

### InterruptAdvisor
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `GetInterruptState()` | — | `table` | Get `{available, cooldownRemaining, shouldInterrupt, urgency}` |

### PrePullChecker
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `RunChecks()` | — | `CheckResult[]` | Run all pre-pull checks (`{name, passed, icon}`) |
| `IsReady()` | — | `boolean` | Check if all pre-pull buffs are active |

---

## UI Layer

### MainDisplay
| Method | Params | Returns | Description |
|--------|--------|---------|-------------|
| `Toggle()` | — | — | Toggle combat-only visibility |
| `ToggleLock()` | — | — | Toggle position lock |
