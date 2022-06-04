# Systematic Quality Assessment of Head Motion

Author: Yukai Zou

E-mail: Y.Zou@soton.ac.uk

If you use this tool in your analysis, please cite:

 - Yukai Zou, Ho-Ching Yang, Yunjie Tong, Angela Darekar, Peter Fransson, Brigitte Vollmer, Finn Lennartsson (2021). A systematic method to visualise and detect motion for paediatric resting-state fMRI datasets. OHBM Annual Meeting, Glasgow, Scotland, United Kingdom.

## Overview

This directory contains scripts that visualise and detect head motion using carpet plot (a type of heatmap that shows signal intensity as colour in 2D matrix). The tool can quickly visualise how long the participants stayed still during the scans, allow inspecting movement among participants, which is more robust and efficient than evaluating the data quality separately. This tool aims to help formalise strategies to quantify and compare motion between groups, apply motion correction techniques, and promptly contact participants for rescan when necessary.



## Get Started

Scripts under this directory need to be run in the following order:

- Do_fsl_preprocess_1_mcf_Melodic_4BIDS.sh
```
bash Do_fsl_preprocess_1_mcf_Melodic_4BIDS.sh <NENAHxxx> <SessionID>
```
    - Example: `bash Do_fsl_preprocess_1_mcf_Melodic_4BIDS.sh NENAHC001 1`
    - Note: One session at a time. Specify `NENAHxxx` without prefix "sub-" (e.g. `NENAH001`, not `sub-NENAH001`).
- get_discard_max_diff.py
```
source activate
python get_discard_max_diff.py /path/to/discarded_vols_vol2volmotion_run-<SessionID>.txt
```
- fd035_outlier_carpetplot.R

## Update Slice Timing for Anonymised Data

For fMRI data being anonymised through Syngo, neither `dcm2niix` or `mrtrix3` can correctly retrieve the SliceTiming information, this is critical for fMRI because slice timing correction is one of the standardised preprocessing steps. To update Slice Timing for the anonymised fMRI data, run the script:

- replace_slicetimings_fMRI.py
```
source activate
python replace_slicetimings_fMRI.py /path/to/func/bold.json /path/to/slicetiming.json
```
### Run fMRIprep after FreeSurfer

**NOTE: `segmentation.sh` should have been completed prior to this step.**

Run the script:

- docker_run_fmriprep_noFS.sh OR docker_run_fmriprep_postFS.sh

### (Optional) Run fMRIprep without FreeSurfer

**NOTE: `segmentation.sh` is not required for this step.**

Run the script:

- docker_run_fmriprep_noFS.sh OR docker_run_fmriprep_noFS.sh
