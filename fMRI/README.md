Scripts for fMRI processing, including:

Datadir is `/derivatives/fMRI/sub-$sID`

## Systematic Quality Assessment of Head Motion

Run scripts in the following order:

- Do_fsl_preprocess_1_mcf_Melodic_4BIDS.sh
- get_discard_max_diff.py
- fd035_outlier_carpetplot.R

## Update Slice Timing for Anonymised Data

For fMRI data being anonymised through Syngo, neither `dcm2niix` or `mrtrix3` can correctly retrieve the SliceTiming information, this is critical for fMRI because slice timing correction is one of the standardised preprocessing steps. To update Slice Timing for the anonymised fMRI data, run the script:

- replace_slicetimings_fMRI.py
```
source activate
python replace_slicetimings_fMRI.py /path/to/func/bold.json /path/to/slicetiming.json
```
## Run fMRIprep after FreeSurfer

**NOTE: `segmentation.sh` should have been completed prior to this step.**

Run the script:

- docker_run_fmriprep_noFS.sh OR docker_run_fmriprep_postFS.sh

## (Optional) Run fMRIprep without FreeSurfer

**NOTE: `segmentation.sh` is not required for this step.**

Run the script:

- docker_run_fmriprep_noFS.sh OR docker_run_fmriprep_noFS.sh
