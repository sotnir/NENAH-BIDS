# QC routines for NENAH-BIDS
Routines for assessing data quality in NENAH MRI data

## sMRI
### rawdata 
#### Eye-balling data using the MRIQC report
- Eye-balling rawdata in MRIQC report
- Assess the MRIQC report output (rudimentary - only assess visually)
- Decide which T1w to use for the sMRI pipeline

Update in `$codedir/QC/QC_MRIQC_anat.tsv`  

The column `QC_rawdata_anat_PASS_1_or_FAIL_0` states if it is a `PASS=1`, `BORDERLINE=0.5` och `FAIL=0`.  
The column `rawdata_anat_TO_USE` states which T1w-images to use for further processing.

### FreeSurfer Segmentation
The FreeSurfer (FS) segmenation resides in `$studydir/derviatives/sMRI_fs-segmentation`. 

#### Eye-balling relevant FS output
To evaluate we inspect each subject's output.  
This is done withe the script `$codedir/sMRI/visualise_fs-segmentation.sh`.  
Specifically evaluate:  
- Whether the surfaces accurately follow the gray matter and white matter boundaries.
- Whether the aseg accurately follows the subcortical intensity boundaries.

Update in `$studydir/derviatives/sMRI_fs-segmentation/QC_fs-segmentation.tsv.`  

The column `qc_fs-segmentation_pass_1_fail_0` states if it is a `PASS=1`, `BORDERLINE=0.5` och `FAIL=0`.  
The column `qc_fs-segmentation_comments` is reserved for comments on the results.

## fMRI
### rawdata 
#### Eye-balling data using the MRIQC report
- Eye-balling rawdata
- Assess MRIQC report output (rudimentary - only assess visually)

Update in `$codedir/QC/QC_MRIQC_func.tsv`

## dMRI
### rawdata 
- Eye-balling rawdata on a per shell basis
- Determine appropriate (motion-free) b0:s in dir-AP and dir-PA to use for TOPUP

Update in `$codedir/QC/QC_dwi.tsv`

The column `QC_rawdata_dwi_PASS_1_FAIL_0` states if it is a `PASS=1`, `BORDERLINE=0.5` or `FAIL=0`.  
The column `rawdata_dir-AP_dwi` states which "dwi_dir-AP" to use.  
The column `rawdata_dir-AP_b0_volume` which "b0" in "dwi_dir-AP" to use for TOPUP.  
The column `rawdata_dir-PA_dwi` states which "dwi_dir-PA" to use.  
The column `rawdata_dir-PA_b0_volume` which "b0" in "dwi_dir-PA" to use for TOPUP.  
The column `optimal_BET_f-value` which "-f" value to use for Brain Extraction using FSL's Bet.  

The "-f" thresholded is decided after having tried several thresholds in dMRI/preprocess_QC.sh and visually deciding on the best. See
https://github.com/sotnir/NENAH-BIDS/blob/8d0355b53b889903c8602d2cddf71e78f48d5c07/dMRI/preprocess_QC.sh#L240-L261  

### dMRI pipeline
QC is preformed of the relevant stages of the dMRI pipeline (see below)  
Logging of QC is done in dMRI-pipeline QC file: `$studydir/derivatives/dMRI/QC_dMRI_pipeline.tsv`.  
Two columns are describe the evaluation:  
- The column `"stage"_pass_1_fail_0` states if it is a `PASS=1`, `BORDERLINE=0.5` or `FAIL=0`.
- The column `"stage"_comments` is reserved for comments on the results.

#### Preprocess 
Primarily based on the FSL's EDDY and its [QC routines](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddyqc/UsersGuide): QUAD and SQUAD
1. Check outliers in `$studydir/derivatives/dMRI/sub-NENAHGRP/qc/squad_quad_cnr/group_qc.pdf` and corresponding invidual files `$studydir/derivatives/dMRI/sub-sID/preproc/eddy/quad/qc_updated.pdf` (Traffic light system GREEN/YELLOW/RED)
2. With the SQAUD/QUAD results in mind, now visually inspect for outliers in post-Eddy data for each subject `$studydir/derivatives/dMRI/sub-sID/dwi/preproc/dwi_den_unr_eddy.mif.gz` and decide whether it should be kept or not.  
Visualisaton of preprocessed data is done with script `$codedir/dMRI/Visualise_QC_Eddy.sh`  

Update in `$studydir/derivatives/dMRI/QC_dMRI_pipeline.tsv`

The column `QC_preprocess_pass_1_fail_0` states if it is a `PASS=1`, `BORDERLINE=0.5` or `FAIL=0`.  
The column `QC_preprocess_comments` is reserved for comments on the results.

Guidance from [EDDY QC paper](https://www.sciencedirect.com/science/article/pii/S1053811918319451) and the paper on the [dMRI pipeline in dHCP](https://www.sciencedirect.com/science/article/pii/S1053811918304889?via%3Dihub)
#### Response
#### CSD  
#### 5TT 
