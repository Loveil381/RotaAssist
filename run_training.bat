@echo off
if not exist data mkdir data

echo ========== Demon Hunter ========== > results.log

echo --- 1. Havoc (specID 577) --- >> results.log
python training/simc_apl_to_dataset.py --spec havoc --output data/havoc.csv >> results.log 2>&1
python training/train_decision_tree.py --input data/havoc.csv --output-lua addon/Data/DecisionTrees/DH_Havoc_DT.lua --output-markov addon/Data/TransitionMatrix/DH_Havoc_TM.lua --spec-id 577 >> results.log 2>&1

echo --- 2. Vengeance (specID 581) --- >> results.log
python training/simc_apl_to_dataset.py --spec vengeance --output data/vengeance.csv >> results.log 2>&1
python training/train_decision_tree.py --input data/vengeance.csv --output-lua addon/Data/DecisionTrees/DH_Vengeance_DT.lua --output-markov addon/Data/TransitionMatrix/DH_Vengeance_TM.lua --spec-id 581 >> results.log 2>&1

echo --- 3. Devourer (specID 1480) --- >> results.log
python training/simc_apl_to_dataset.py --spec devourer --output data/devourer.csv >> results.log 2>&1
python training/train_decision_tree.py --input data/devourer.csv --output-lua addon/Data/DecisionTrees/DH_Devourer_DT.lua --output-markov addon/Data/TransitionMatrix/DH_Devourer_TM.lua --spec-id 1480 >> results.log 2>&1

echo ========== Evoker ========== >> results.log

echo --- 4. Devastation (specID 1467) --- >> results.log
python training/simc_apl_to_dataset.py --spec devastation --output data/devastation.csv >> results.log 2>&1
python training/train_decision_tree.py --input data/devastation.csv --output-lua addon/Data/DecisionTrees/EVO_Devastation_DT.lua --output-markov addon/Data/TransitionMatrix/EVO_Devastation_TM.lua --spec-id 1467 >> results.log 2>&1

echo --- 5. Augmentation (specID 1473) --- >> results.log
python training/simc_apl_to_dataset.py --spec augmentation --output data/augmentation.csv >> results.log 2>&1
python training/train_decision_tree.py --input data/augmentation.csv --output-lua addon/Data/DecisionTrees/EVO_Augmentation_DT.lua --output-markov addon/Data/TransitionMatrix/EVO_Augmentation_TM.lua --spec-id 1473 >> results.log 2>&1

echo --- 6. Preservation (specID 1468) --- >> results.log
python training/simc_apl_to_dataset.py --spec preservation --output data/preservation.csv >> results.log 2>&1
python training/train_decision_tree.py --input data/preservation.csv --output-lua addon/Data/DecisionTrees/EVO_Preservation_DT.lua --output-markov addon/Data/TransitionMatrix/EVO_Preservation_TM.lua --spec-id 1468 >> results.log 2>&1

echo Done >> results.log
