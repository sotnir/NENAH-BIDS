# Data organisation
The study directory (**studydir**) `NENAH_BIDS` is [BIDS-organised](https://bids-specification.readthedocs.io/en/stable/) and is located in `/local/scratch/disk2/research/NENAH_BIDS`

In line with the BIDS-structure, all data processing is done in the **derivatives**-folder `/derivatives`, where all the **dMRI** data processing goes into `/derivatives/dMRI`.

The data directory (**datadir**) for each subject (identified by its Subject_ID=$sID, e.g. NENAHC004) is `/derivatives/dMRI/sub-$sID` and has the following sub-folders
```
/derivatives/dMRI/sub-$sID
├── anat    <= anatomy-related images and processing
├── dwi     <= dMRI-related images and processing
├── fmap    <= field map-related images and processing
├── logs    <= logs
├── qc      <= quality control
└── xfm     <= transformations between spaces
```

# Processing data
This study uses **bash** and **python** scripts for the dMRI processing. 

The processing essentially follows instructions in the [BATMAN tutorial](https://osf.io/pm9ba/) and for [FBA analysis in MRtrix](https://mrtrix.readthedocs.io/en/latest/fixel_based_analysis/mt_fibre_density_cross-section.html#fibre-density-and-cross-section-multi-tissue-csd)

## Before start

Make sure your `.bashrc` file contains the paths to all the dependent packages.

- MRtrix3
- dcm2niix
- heudiconv
- ANTs
- FSL

## Running scripts 
Scripts are intended to run from the study directory (i.e. /local/scratch/disk2/research/NENAH_BIDS)

To run a bash-script, make sure that you are in studydir and then run the script
```
cd /local/scratch/disk2/research/NENAH_BIDS
bash code/NENAH-BIDS/dMRI/preprocess_QC.sh NENAH007
```
When a bash-scripts is run without an input-arguments (or with flag -h/-help/--help), it returns the usage  
E.g.
```
bash code/NENAH-BIDS/dMRI/preprocess_QC.sh
usage: preprocess_QC.sh sID [options]
Script to preprocess dMRI data
Preprocessing is gathered in /preproc
Uses inputs from QC-file
1. MP-PCA Denoising and Gibbs Unringing
2. TOPUP and EDDY for motion- and susceptebility image distortion correction
3. N4 biasfield correction
4. Normalisation
5. Creation of a mean B0, B1000 and B2600 images (as average from normalised unwarped b0s)
6. Calculation of tensor and tensor maps (FA, MD etc)

Arguments:
  sID    Subject ID   (e.g. NENAHC001)
Options:
  -QC                   QC file with entries for dir-AP, dir-PA and with good quality b0s for TOPUP (see below how entries should be organized in QC-file) (default: $codedir/../QC/QC_dwi.csv)
  -d / -data-dir        <directory> The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help   Print usage.
```
For the usage, input arguments/options and the processing steps are understood. For more details, as well as more information on output, can be found in the script.

## Overview of scripts in the dMRI pipeline
Scripts should be run in the following order:

- preprocess_QC.sh
- response.sh
- (average_response.sh)
- (upsample_dwi.sh)
- csd.sh
- (normalisation.sh)

Need 5TT from sMRI
- registration.sh
- 5tt.sh
- tractography.sh
- connectome.sh

A book-keeping, `derivatives/dMRI/Subject_Tracker_dMRI_pipeline.csv`, is used for keeping track of the status for each subjects in the dMRI pipeline.  

## Specific steps/scripts

### Preprocess_QC 
Script to preprocess dMRI data.  

Input:  `QC-file` and NIfTI-images in `/rawdata/$sID`  
Output: Orignal and various intermediate and preprocessed files in `derivatives/dMRI/$sID/dwi`

Specific steps:
1. MP-PCA Denoising and Gibbs Unringing
2. TOPUP and EDDY for motion- and susceptebility image distortion correction
3. N4 biasfield correction
4. Normalisation
5. Creation of a mean B0, B1000 and B2600 images (as average from normalised unwarped b0s)
6. Calculation of tensor and tensor maps (FA, MD etc)

The output lands in `/dwi`where, specifically, the preprocessing, with intermediate files, are put in `dwi/preproc`:

```
dwi
├── dti         <= DTI tensor-estimation and calculated parametric maps
│   ├── adc.mif.gz
│   ├── ad.mif.gz
│   ├── dt.mif.gz
│   ├── ev.mif.gz
│   ├── fa.mif.gz
│   └── rd.mif.gz
├── dwi.mif.gz                  <= original data
├── dwi_preproc.mif.gz          <= preprocessed data from /preproc
├── dwi_preproc_norm-ind.mif.gz <= preprocessed and normalised data
├── mask.mif.gz                 <= mask (calculated in /preproc)
├── meanb0_brain.mif.gz         <= mean b0 shell data (skull-stripped)
├── meanb0.mif.gz               <= mean b0 shell data
├── meanb1000_brain.mif.gz      <= mean b1000 shell data (skull-stripped)
├── meanb1000.mif.gz            <= mean b0 shell data 
├── meanb2600_brain.mif.gz      <= mean b2600 shell data (skull-stripped)
├── meanb2600.mif.gz            <= mean b2600 shell data
├── orig        <= original data
│   ├── sub-NENAH$sID_dir-AP_run-1_dwi.bval
│   ├── sub-NENAH$sID_dir-AP_run-1_dwi.bvec
│   ├── sub-NENAH$sID_dir-AP_run-1_dwi.json
│   ├── sub-NENAH$sID_dir-AP_run-1_dwi.mif.gz
│   ├── sub-NENAH$sID_dir-AP_run-1_dwi.nii.gz
│   ├── sub-NENAH$sID_dir-PA_run-1_dwi.bval
│   ├── sub-NENAH$sID_dir-PA_run-1_dwi.bvec
│   ├── sub-NENAH$sID_dir-PA_run-1_dwi.json
│   ├── sub-NENAH$sID_dir-PA_run-1_dwi.mif.gz
│   └── sub-NENAH$sID_dir-PA_run-1_dwi.nii.gz
└── preproc     <= folders and files/intermediate files in preprocessing steps
    ├── denoise
    ├── dwiAP.mif.gz
    ├── dwi_den.mif.gz
    ├── dwi_den_unr_eddy.mif.gz
    ├── dwi_den_unr_eddy_unbiased.mif.gz
    ├── dwi_den_unr.mif.gz
    ├── dwi.mif.gz
    ├── dwiPA.mif.gz
    ├── eddy
    ├── mask.mif.gz
    ├── meanb1000tmp.nii.gz
    ├── topup
    └── unring
```
