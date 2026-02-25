# RotaAssist

[![WoW Version](https://img.shields.io/badge/WoW-12.0_Midnight-blueviolet)](https://worldofwarcraft.blizzard.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CurseForge Downloads](https://img.shields.io/curseforge/dt/000000?color=orange&label=CurseForge)](https://www.curseforge.com/wow/addons/rotaassist)

**RotaAssist** — WoW 12.0 Midnight 下最智能的输出循环辅助插件。
*The smartest rotation assistant addon for WoW 12.0 Midnight.*

---

## ✨ Features / 功能亮点

| Feature | Description |
|---------|-------------|
| 🧠 **AI Prediction** | Decision tree + Markov chain predictions that learn from YOUR play style |
| ⚡ **Multi-Source Fusion** | Blends Blizzard C_AssistedCombat, APL, and AI into one weighted recommendation |
| 🎯 **Combat Phase Detection** | Automatically detects Burst, AoE, Execute, Emergency, and 8 more phases |
| 📊 **Accuracy Tracking** | Real-time accuracy meter comparing your casts against optimal |
| 🔔 **Interrupt Alerts** | 12.0-compliant interrupt reminders with sound + visual flash |

## 🎮 Supported Classes / 支持职业

| Class | Specialization | specID |
|-------|---------------|--------|
| Demon Hunter | Havoc | 577 |
| Demon Hunter | Vengeance | 581 |
| Demon Hunter | Devourer | 1480 |

> More classes coming soon! Contributions welcome.

## 📦 Installation / 安装

### CurseForge (Recommended)
1. Install via [CurseForge App](https://www.curseforge.com/wow/addons/rotaassist)
2. Done! The addon auto-updates.

### Manual Install
1. Download the latest release from [GitHub Releases](https://github.com/yourname/rotaassist/releases)
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/RotaAssist/`
3. Restart WoW or `/reload`

## 🖥️ Screenshots

> Screenshots will be added after first public release.

<!-- ![Main Display](docs/screenshots/main_display.png) -->
<!-- ![Phase Indicator](docs/screenshots/phase_indicator.png) -->
<!-- ![Accuracy Meter](docs/screenshots/accuracy_meter.png) -->

## ⌨️ Slash Commands

| Command | Description |
|---------|-------------|
| `/ra` | Toggle main display |
| `/ra config` | Open configuration panel |
| `/ra accuracy` | Print accuracy history |
| `/ra reset` | Reset saved position |

## ⚙️ Configuration

Right-click the main display to access quick settings:
- **Lock/Unlock** position
- **Combat-only** mode
- **Phase Indicator** toggle
- **Accuracy Meter** toggle
- **Scale** adjustment (75% – 150%)

## 🔬 Training Pipeline (Developer Only)

The `training/` directory contains Python scripts to generate decision tree
and Markov matrix data files. **Players never need to run Python.**

See [`training/README.md`](training/README.md) for full instructions.

```bash
pip install -r training/requirements.txt
python training/simc_apl_to_dataset.py --spec havoc --output data/havoc.csv
python training/train_decision_tree.py --input data/havoc.csv \
  --output-lua addon/Data/DecisionTrees/DH_Havoc_DT.lua \
  --output-markov addon/Data/TransitionMatrix/DH_Havoc_TM.lua --spec-id 577
```

## 📜 License

[MIT License](LICENSE)

## 🙏 Acknowledgments

- **Blizzard Entertainment** — C_AssistedCombat API
- **SimulationCraft** — APL reference data
- **MaxDPS** / **Hekili** — Inspiration for rotation-assist addon design
- **Ace3 Libraries** — AceAddon, AceDB, AceEvent, AceLocale, AceTimer
