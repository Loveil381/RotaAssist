#!/usr/bin/env python3
"""
RotaAssist — Markov Transition Matrix Builder

Reads a training CSV and builds a spell-to-spell transition probability
matrix, then exports it as a Lua file for the addon.

Usage:
    python markov_builder.py --input data/havoc_dataset.csv \
        --output ../addon/Data/TransitionMatrix/DH_Havoc_TM.lua --spec-id 577
"""

import argparse
import datetime
import os
import sys
from collections import defaultdict
from typing import Dict, Tuple

import pandas as pd

# Reverse spell map for comments
SPELL_NAMES: Dict[int, str] = {
    162243: "Demon's Bite",
    162794: "Chaos Strike",
    198013: "Eye Beam",
    188499: "Blade Dance",
    210152: "Death Sweep",
    201427: "Annihilation",
    258920: "Immolation Aura",
    191427: "Metamorphosis",
    195072: "Fel Rush",
    198793: "Vengeful Retreat",
    185123: "Throw Glaive",
    370965: "The Hunt",
    258860: "Essence Break",
    342817: "Glaive Tempest",
    258925: "Fel Barrage",
    228477: "Soul Cleave",
    247454: "Spirit Bomb",
    263642: "Fracture",
    204596: "Sigil of Flame",
    204021: "Fiery Brand",
    203720: "Demon Spikes",
    189110: "Infernal Strike",
    320341: "Bulk Extraction",
    183752: "Disrupt",
    212084: "Fel Devastation",
}

MIN_PROB = 0.05  # Filter transitions below this threshold


def build_markov_from_df(df: pd.DataFrame) -> Dict[int, Dict[int, float]]:
    """Build normalized transition matrix from consecutive target_spellID pairs."""
    counts: Dict[int, Dict[int, int]] = defaultdict(lambda: defaultdict(int))

    targets = df["target_spellID"].tolist()
    for i in range(len(targets) - 1):
        from_id = int(targets[i])
        to_id = int(targets[i + 1])
        counts[from_id][to_id] += 1

    # Also use lastSpellID → target_spellID as transitions
    for _, row in df.iterrows():
        from_id = int(row["lastSpellID"])
        to_id = int(row["target_spellID"])
        counts[from_id][to_id] += 1

    # Normalize
    matrix: Dict[int, Dict[int, float]] = {}
    for from_id, row in counts.items():
        total = sum(row.values())
        if total == 0:
            continue
        matrix[from_id] = {}
        for to_id, cnt in row.items():
            prob = cnt / total
            if prob >= MIN_PROB:
                matrix[from_id][to_id] = round(prob, 4)

    return matrix


def export_markov_lua(
    matrix: Dict[int, Dict[int, float]],
    spec_id: int,
    output_path: str,
):
    """Write transition matrix to Lua file."""
    today = datetime.date.today().isoformat()
    lines = []

    def _add(t: str):
        lines.append(t)

    _add(f"--- RotaAssist Markov Transition Matrix (specID {spec_id})")
    _add(f"--- Auto-generated on {today}")
    _add("-- 自动生成的马尔可夫矩阵 / 自動生成マルコフ行列")
    _add("")
    _add("local _, NS = ...")
    _add("local RA = NS.RA")
    _add("local TM = {}")
    _add("")
    _add(f"TM.specID = {spec_id}")
    _add(f'TM.generatedDate = "{today}"')
    _add("")
    _add("TM.matrix = {")

    for from_id in sorted(matrix.keys()):
        from_name = SPELL_NAMES.get(from_id, "Unknown")
        _add(f"    [{from_id}] = {{  -- {from_name}")
        for to_id, prob in sorted(matrix[from_id].items(), key=lambda x: -x[1]):
            to_name = SPELL_NAMES.get(to_id, "Unknown")
            _add(f"        [{to_id}] = {prob},  -- -> {to_name}")
        _add("    },")

    _add("}")
    _add("")

    # GetTopTransitions helper
    _add("--- Get top N most probable next spells.")
    _add("--- @param fromSpellID number")
    _add("--- @param topN number")
    _add("--- @return table")
    _add("function TM.GetTopTransitions(fromSpellID, topN)")
    _add("    topN = topN or 3")
    _add("    local row = TM.matrix[fromSpellID]")
    _add("    if not row then return {} end")
    _add("    local result = {}")
    _add("    for sid, prob in pairs(row) do")
    _add("        result[#result + 1] = {spellID = sid, probability = prob}")
    _add("    end")
    _add("    table.sort(result, function(a, b) return a.probability > b.probability end)")
    _add("    local top = {}")
    _add("    for i = 1, math.min(topN, #result) do top[i] = result[i] end")
    _add("    return top")
    _add("end")
    _add("")
    _add("RA.TransitionMatrices = RA.TransitionMatrices or {}")
    _add(f"RA.TransitionMatrices[{spec_id}] = TM")
    _add("")

    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    with open(output_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))

    print(f"Markov matrix written to {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Build Markov matrix → Lua")
    parser.add_argument("--input", required=True, help="Training CSV")
    parser.add_argument("--output", required=True, help="Output Lua path")
    parser.add_argument("--spec-id", type=int, required=True)
    args = parser.parse_args()

    df = pd.read_csv(args.input)
    matrix = build_markov_from_df(df)
    export_markov_lua(matrix, args.spec_id, args.output)


if __name__ == "__main__":
    main()
