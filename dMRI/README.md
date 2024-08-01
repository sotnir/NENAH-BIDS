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
4. Brain mask estimation (with FSL's BET using different values for -f => see code)  

Arguments:
  sID    Subject ID   (e.g. NENAHC001)
Options:
  -QC                   QC file with entries for dir-AP, dir-PA and with good quality b0s for TOPUP (see below how entries should be organized in QC-file) (default: $codedir/../QC/QC_dwi.csv)
  -d / -data-dir        <directory> The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help   Print usage.
```
For the usage, input arguments/options and the processing steps are understood. More details, as well as more information on output, can be found in the script.

## Overview of scripts in the dMRI pipeline
Scripts should be run in the following order:

- preprocess_QC.sh
- response.sh
- average_response.sh
- upsample_dwi.sh
- csd.sh

  

Need 5TT from sMRI
- registration.sh
- combine_segmentations.sh
- 5tt.sh

Scripts incorporating the outputs from sMRI and dMRI above:
- tractography.sh
- thalamic_connectome.sh

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
4. Brain mask estimation (with FSL's BET using different values for -f => see code)  


The output lands in `/dwi`where, specifically, the preprocessing, with intermediate files, are put in `dwi/preproc`:

```
dwi
├── dwi.mif.gz                  <= original data
├── dwi_preproc.mif.gz          <= preprocessed data from /preproc
├── mask.mif.gz                 <= mask (calculated in /preproc)
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
### Response function estimation (response.sh / average_response.sh)
Estimate response functions for individual subjects and/or calculate the average accross all subjects. 

#### response.sh
Inputs: `dwi_preproc.mif.gz` and `mask.mif.gz` from preprocessing.  
Outputs: Response function estimations for white matter, gray matter and CSF in `derivatives/dMRI/sub-ID/dwi/response`. 

```
Response
├── dhollander_csf_dwi_preproc.txt
├── dhollander_gm_dwi_preproc.txt
├── dhollander_sf_dwi_preproc.mif.gz
└── dhollander_wm_dwi_preproc.txt
```
#### average_response.sh
Runs response.sh for all subjects (unless relevant files already exists).  
Calculates the average response function across all subjects.  

Inputs: Each subject-unique response function.  
Outputs: An average response function for white matter, gray matter and CSF in `derivatives/dMRI/NENAHGRP/dwi/response`.

```
NENAHGRP
dwi
└── response
    ├── dhollander_csf_dwi_preproc.txt
    ├── dhollander_gm_dwi_preproc.txt
    └──dhollander_wm_dwi_preproc.txt
```

### Upsampling of DWI-data (upsample.sh) 
Script to upsample DWI data (2x2x2 --> 1.25x1.25x1.25) and use it to generate high resolution meanb1000, create brain masks
and calculate diffusion tensor and tensor parametric maps. 

Inputs: `dwi_preproc.mif.gz`  
Outputs: `dwi_preproc_hires.mif.gz` and new 'hires' meanb, mask and DTI files in `derivatives/dMRI/sub-ID/dwi/` and `derivatives/dMRI/sub-ID/dwi/dti` respectively.

dwi  
├── dwi.mif.gz  
├── dwi_preproc_hires.mif.gz  
├── dwi_preproc.mif.gz       
├── mask.mif.gz  
├── mask_space-dwi_hires.mif.gz  
├── meanb0_dwi_preproc_hires.mif.gz  
├── meanb1000_dwi_preproc_hires.mif.gz  
├── meanb2600_dwi_preproc_hires.mif.gz  
├── dti         <= DTI tensor-estimation and calculated parametric maps  
│   ├── adc_hires.mif.gz  
│   ├── ad_hires.mif.gz  
│   ├── dt_hires.mif.gz  
│   ├── ev_hires.mif.gz  
│   ├── fa_hires.mif.gz  
│   └── rd_hires.mif.gz  


### csd.sh
Script to compute the fiber orientation distribution (FOD) using constrained spherical convolution (CSD).
By running with the script with the '-transform 1' option, the FODs will also be given in anatomical space.

Inputs: The `dwi_preproc_hires` and `mask_space-dwi_hires` files from the upsampling step. Subject-unique response files (from response.sh) or group average response files (average_response.sh)  
Outputs: Normalised FOD-images for each subjects in (in `derivatives/dMRI/sub-ID/dwi/csd`)

```
csd
├── csd-dhollander_csf_dwi_preproc_hires.mif.gz
├── csd-dhollander_csf_norm_dwi_preproc_hires.mif.gz
├── csd-dhollander_csf_norm_space-anat.mif.gz
├── csd-dhollander_gm_dwi_preproc_hires.mif.gz
├── csd-dhollander_gm_norm_dwi_preproc_hires.mif.gz
├── csd-dhollander_gm_norm_space-anat.mif.gz
├── csd-dhollander_wm_dwi_preproc_hires.mif.gz
├── csd-dhollander_wm_norm_dwi_preproc_hires.mif.gz
└── csd-dhollander_wm_norm_space-anat.mif.gz
```

## Scripts running on sMRI-data

Prior to these scripts, the T1-weighted image is segmented using FreeSurfer and HIPS-THOMAS. 

### combine_segmentations.sh
Script to replace the sub-cortical gray matter structure delineations in the FreeSurfer segmentation with FSL FIRST  
and then combine the newly enhanced FreeSurfer/FSL FIRST segmentation with HIPS-THOMAS.  
This script also utilizes LUTs in various re-mapping steps. These can be found here on the GitHub in the `label_names` folder.  

Inputs: FreeSurfers `aparc+aseg.mgz` and HIPS-THOMAS left/right `thomasfull.nii.gz/thomasrfull.nii.gz`  
Outputs: A combined FreeSurfer and HIPS-THOMAs segmentation with enhanced sub-cortical gray matter structures `aparc+aseg_thomas-thalamic_gmfix.mif.gz`
in `derivatives/dMRI/sub-ID/anat`.


### 5TT.sh
Script to generate five-tissue-type (5TT) images of the combined segmentations.  
To be called with the desired output-space (e.g. diffusion (dwi) or anatomical (anat)).

Inputs: The combined segmentation `aparc+aseg_gmfix.mif.gz` from `combine_segmentations.sh`.  
Outputs: A 5TT image with accompanying files for visualisation and a mask of the gray and white matter interface, output in either `derivatives/dMRI/sub-ID/dwi/5tt` or `derivatives/dMRI/sub-ID/anat/5tt`.  

```
5tt
├── 5tt_space-anat_gmwmi.mif.gz
├── 5tt_space-anat.mif.gz
└── 5tt_space-anat_vis.mif.gz
```
## Tractography and generating connectivity matrices

### tractography.sh

Performs whole-brain tractography and SIFT/SIFT2-filtering. Can be done in either anatomical (default) or diffusion space (with `-space dwi`).  
This script has the following options:  
```
Options:
  -space      Do tractography in another space, either diffusion or anatomical (dwi or anat) (default: anat)
  -csd				CSD mif.gz-file in (default: derivatives/dMRI/sub-sID/SPACE/csd/csd-dhollander_wm_norm_space-SPACE.mif.gz)
  -5TT				5TT mif.gz-file  (default: derivatives/dMRI/sub-sID/SPACE/5tt/5tt_space-SPACE.mif.gz)
  -sift				SIFT-method [1=sift or 2=sift2] (default: 2)
  -nbr				Number of streamlines in whole-brain tractogram (default: 10M)
  -threads			Number of threads for parallell processing (default: 18)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help           Print usage.
"
```

Inputs: The FOD from csd.sh `csd-dhollander_wm_norm_space-anat.mif.gz`, the 5TT image `5tt_space-anat.mif.gz` and the gmwm mask `5tt_space-anat_gmwmi.mif.gz` from 5tt.sh.  
Outputs: The streamlines file `whole_brain_10M_space-anat.tck` together with the SIFT/SIFT2 filtering, a file with only 10% streamlines for visualisation and the SIFT proportionality coefficient (mu) as a text file in `derivatives/dMRI/sub-ID/anat/tractography` (or the dwi-folder if done in diffusion space).  

```
tractography
├── whole_brain_10M_sift2_space-anat_mu.txt
├── whole_brain_10M_space-anat_edit100k.tck
├── whole_brain_10M_space-anat_sift2.txt
└── whole_brain_10M_space-anat.tck

```

### thalamic_connectome.sh
Script to, as of now, generate two connectomes. One default connectome in which connectivity is quantified as the sum of streamline weights from the SIFT2 filtering and one where the value of connectivity is the mean fractional anisotropy (FA). At the moment this script generates connectivity between thalamus and the lobes.   

This is done by the following steps (also see image below):  
- The FreeSurfer parcellation image is re-mapped to only include the cortex
and sub-cortical structures excluding the thalamus.  
- The HIPS-THOMAS parcellation image is likewise re-mapped to match a
LUT containing labels for both the lobes and thalamus.
- The images are combined into a single thalamo-cortical parcellation image,
giving priority to the HIPS-THOMAS image if there are any voxels with
overlap.

The LUTs used in this conversion is also located in the `label_names` folder here on GitHub. 

![bild](https://github.com/user-attachments/assets/e8109a97-ebf3-4209-bea8-f71f1b275e57)

