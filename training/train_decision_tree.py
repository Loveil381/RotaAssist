#!/usr/bin/env python3
"""
RotaAssist — Decision Tree Trainer

Loads a CSV dataset produced by simc_apl_to_dataset.py, trains a
DecisionTreeClassifier, prints metrics, and exports to Lua + Markov.

Usage:
    python train_decision_tree.py \
        --input data/havoc_dataset.csv \
        --output-lua ../addon/Data/DecisionTrees/DH_Havoc_DT.lua \
        --output-markov ../addon/Data/TransitionMatrix/DH_Havoc_TM.lua \
        --spec-id 577
"""

import argparse
import os
import sys

import numpy as np
import pandas as pd
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier, export_graphviz

from sklearn2lua import tree_to_lua
from markov_builder import build_markov_from_df, export_markov_lua


FEATURE_COLS = [
    "lastSpellID",
    "secondLastSpellID",
    "thirdLastSpellID",
    "timeSinceLastCast",
    "nameplateCount",
    "secondaryResource",
    "secondaryResourceMax",
    "blizzardRecommendation",
    "combatDuration",
    "specID",
]
LABEL_COL = "target_spellID"


def main():
    parser = argparse.ArgumentParser(description="Train DT + export Lua")
    parser.add_argument("--input", required=True, help="Training CSV")
    parser.add_argument("--output-lua", required=True, help="Lua DT output")
    parser.add_argument("--output-markov", default=None, help="Lua Markov output")
    parser.add_argument("--output-dot", default=None, help=".dot visualization")
    parser.add_argument("--spec-id", type=int, required=True)
    parser.add_argument("--max-depth", type=int, default=10)
    parser.add_argument("--min-samples-leaf", type=int, default=20)
    parser.add_argument("--test-size", type=float, default=0.2)
    args = parser.parse_args()

    # ---- Load ----
    df = pd.read_csv(args.input)
    print(f"Loaded {len(df)} rows from {args.input}")

    X = df[FEATURE_COLS]
    y = df[LABEL_COL]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=args.test_size, random_state=42, stratify=y
    )

    # ---- Train ----
    clf = DecisionTreeClassifier(
        max_depth=args.max_depth,
        min_samples_leaf=args.min_samples_leaf,
        random_state=42,
    )
    clf.fit(X_train, y_train)

    y_pred = clf.predict(X_test)
    acc = accuracy_score(y_test, y_pred)

    print(f"\n=== Test Accuracy: {acc:.2%} ===\n")
    print(classification_report(y_test, y_pred, zero_division=0))

    print("Feature importances:")
    for name, imp in sorted(
        zip(FEATURE_COLS, clf.feature_importances_), key=lambda x: -x[1]
    ):
        print(f"  {name:30s}  {imp:.4f}")

    # ---- Export Lua DT ----
    os.makedirs(os.path.dirname(args.output_lua) or ".", exist_ok=True)
    class_names = [str(c) for c in clf.classes_]
    tree_to_lua(clf, FEATURE_COLS, class_names, args.spec_id, args.output_lua, acc)

    # ---- Export .dot ----
    if args.output_dot:
        export_graphviz(
            clf,
            out_file=args.output_dot,
            feature_names=FEATURE_COLS,
            class_names=class_names,
            filled=True,
            rounded=True,
        )
        print(f"Graphviz dot written to {args.output_dot}")

    # ---- Export Markov ----
    if args.output_markov:
        os.makedirs(os.path.dirname(args.output_markov) or ".", exist_ok=True)
        matrix = build_markov_from_df(df)
        export_markov_lua(matrix, args.spec_id, args.output_markov)

    print("\nDone.")


if __name__ == "__main__":
    main()
