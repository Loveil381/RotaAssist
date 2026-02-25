# RotaAssist Training Pipeline

Offline tools to generate decision tree and Markov transition matrix Lua files
for the RotaAssist WoW addon. **Players never run Python** — only developers
use these scripts; the output `.lua` files are committed to the addon repo.

## Directory Structure

```
training/
├── requirements.txt          # Python deps
├── README.md                 # This file
├── simc_apl_to_dataset.py    # SimC APL → CSV training data
├── train_decision_tree.py    # CSV → scikit-learn DT → Lua export
├── sklearn2lua.py            # sklearn tree → pure Lua converter
├── markov_builder.py         # CSV → Markov transition Lua file
└── data/                     # (gitignored) generated CSV datasets
```

## Quick Start

```bash
cd training
pip install -r requirements.txt

# 1. Generate training data from built-in APL
python simc_apl_to_dataset.py --spec havoc --output data/havoc_dataset.csv
python simc_apl_to_dataset.py --spec vengeance --output data/vengeance_dataset.csv

# 2. Train decision tree + export Lua
python train_decision_tree.py \
  --input data/havoc_dataset.csv \
  --output-lua ../addon/Data/DecisionTrees/DH_Havoc_DT.lua \
  --output-markov ../addon/Data/TransitionMatrix/DH_Havoc_TM.lua \
  --spec-id 577

python train_decision_tree.py \
  --input data/vengeance_dataset.csv \
  --output-lua ../addon/Data/DecisionTrees/DH_Vengeance_DT.lua \
  --output-markov ../addon/Data/TransitionMatrix/DH_Vengeance_TM.lua \
  --spec-id 581

# 3. (Optional) Build Markov matrix separately
python markov_builder.py --input data/havoc_dataset.csv \
  --output ../addon/Data/TransitionMatrix/DH_Havoc_TM.lua --spec-id 577
```

## Updating for New Patches

1. Edit the built-in APL strings in `simc_apl_to_dataset.py` or supply
   `--apl-file path/to/custom.simc`.
2. Re-run the pipeline above.
3. Commit the updated `.lua` files under `addon/Data/`.
