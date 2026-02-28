if (!(Test-Path data)) { mkdir data }

""
========== Demon Hunter =========="" | Out-File -Append results.log

""
--- 1. Havoc (specID 577) ---"" | Out-File -Append results.log
python training/simc_apl_to_dataset.py --spec havoc --output data/havoc.csv 2>&1 | Out-File -Append results.log
python training/train_decision_tree.py --input data/havoc.csv --output-lua addon/Data/DecisionTrees/DH_Havoc_DT.lua --output-markov addon/Data/TransitionMatrix/DH_Havoc_TM.lua --spec-id 577 2>&1 | Out-File -Append results.log

""
--- 2. Vengeance (specID 581) ---"" | Out-File -Append results.log
python training/simc_apl_to_dataset.py --spec vengeance --output data/vengeance.csv 2>&1 | Out-File -Append results.log
python training/train_decision_tree.py --input data/vengeance.csv --output-lua addon/Data/DecisionTrees/DH_Vengeance_DT.lua --output-markov addon/Data/TransitionMatrix/DH_Vengeance_TM.lua --spec-id 581 2>&1 | Out-File -Append results.log

""
--- 3. Devourer (specID 1480) ---"" | Out-File -Append results.log
python training/simc_apl_to_dataset.py --spec devourer --output data/devourer.csv 2>&1 | Out-File -Append results.log
python training/train_decision_tree.py --input data/devourer.csv --output-lua addon/Data/DecisionTrees/DH_Devourer_DT.lua --output-markov addon/Data/TransitionMatrix/DH_Devourer_TM.lua --spec-id 1480 2>&1 | Out-File -Append results.log

""
========== Evoker =========="" | Out-File -Append results.log

""
--- 4. Devastation (specID 1467) ---"" | Out-File -Append results.log
python training/simc_apl_to_dataset.py --spec devastation --output data/devastation.csv 2>&1 | Out-File -Append results.log
python training/train_decision_tree.py --input data/devastation.csv --output-lua addon/Data/DecisionTrees/EVO_Devastation_DT.lua --output-markov addon/Data/TransitionMatrix/EVO_Devastation_TM.lua --spec-id 1467 2>&1 | Out-File -Append results.log

""
--- 5. Augmentation (specID 1473) ---"" | Out-File -Append results.log
python training/simc_apl_to_dataset.py --spec augmentation --output data/augmentation.csv 2>&1 | Out-File -Append results.log
python training/train_decision_tree.py --input data/augmentation.csv --output-lua addon/Data/DecisionTrees/EVO_Augmentation_DT.lua --output-markov addon/Data/TransitionMatrix/EVO_Augmentation_TM.lua --spec-id 1473 2>&1 | Out-File -Append results.log

""
--- 6. Preservation (specID 1468) ---"" | Out-File -Append results.log
python training/simc_apl_to_dataset.py --spec preservation --output data/preservation.csv 2>&1 | Out-File -Append results.log
python training/train_decision_tree.py --input data/preservation.csv --output-lua addon/Data/DecisionTrees/EVO_Preservation_DT.lua --output-markov addon/Data/TransitionMatrix/EVO_Preservation_TM.lua --spec-id 1468 2>&1 | Out-File -Append results.log

