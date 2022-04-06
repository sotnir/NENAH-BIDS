This is just a simple readme file to be updated later.

Current indended use: 

Files and outputs all stored in same folder (will be addapted for more suitable file structure later), the 'gen' notebooks are run once, and then analysis conducted in the other notebooks. This will be adapted when study direction is more stable into a set of functions and scripts and some standard analysis scripts and outputs


Files within this folders are:

## Generator files - these create and safe various dictionaries and data frames for analysis - will be broken into scripts
 - comp_dict_gen.ipynb: Generate and save dictionaries that compare tractography run and re-runs. Similar to main_gen, it will be broken into scripts.
 - main_gen.ipynb: The main file that generates metrics. To be broken into functions/scripts instead of a standalone notebook

## Files that will read in outputs from comp_dict_gen, main_gen and MST_gen
 - Case_control comparisons.ipynb 
 - Intra_subject comparisons.ipynb: will read in outputs from comp_dict_gena and main_gen
 - Node_run_comparisons.ipynb
 - binary_comp_visualisations.ipynb
