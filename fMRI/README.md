Scripts for fMRI processing, including:

Datadir is `/derivatives/fMRI/sub-$sID`

Run scripts in the following order:

- Do_fsl_preprocess_1_mcf_Melodic_4BIDS.sh
- get_discard_max_diff.py
- fd035_outlier_carpetplot.R
- docker_run_fmriprep_noFS.sh OR docker_run_fmriprep_postFS.sh
