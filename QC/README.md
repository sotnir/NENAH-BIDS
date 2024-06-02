# QC routines for NENAH-BIDS
Routines for assessing data quality in NENAH MRI data

## sMRI
### rawdata 
#### Eye-balling data using the MRIQC report
- Eye-balling rawdata in MRIQC report
- Assess the MRIQC report output (rudimentary - only assess visually)
- Decide which T1w to use for the sMRI pipeline

Update in `$codedir/QC/QC_MRIQC_anat.tsv`

### FreeSurfer Segmentation
The FreeSurfer (FS) segmenation resides in `$studydir/derviatives/sMRI_fs-segmentation`. 

To evaluate we inspect each subject's output.  
This is done withe the script `$codedir/sMRI/visualise_fs-segmentation.sh`.  
- Whether the surfaces accurately follow the gray matter and white matter boundaries.
- Whether the aseg accurately follows the subcortical intensity boundaries.

Results are stored in $studydir/derviatives/sMRI_fs-segmentation/QC_fs-segmentation.tsv.  
Two columns are describe the evaluation: `qc_fs-segmentation_pass_1_fail_0` and `qc_fs-segmentation_comments`

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

### dMRI pipeline
QC is preformed of the relevant stages of the dMRI pipeline (see below)  
Logging of QC is done in dMRI-pipeline QC file: `$studydir/derivatives/dMRI/QC_dMRI_pipeline.tsv`.  
Two columns are describe the evaluation: `stage_pass_1_fail_0` and `stage_comments`
#### Preprocess 
Primarily based on the FSL's EDDY and its [QC routines](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddyqc/UsersGuide): QUAD and SQUAD
- Check outliers in `$studydir/derivatives/dMRI/sub-NENAHGRP/qc/squad_quad_cnr/group_qc.pdf` and corresponding invidual files `$studydir/derivatives/dMRI/sub-sID/preproc/eddy/quad/qc_updated.pdf` (Traffic light system GREEN/YELLOW/RED)
- With the SQAUD/QUAD results in mind, now visually inspect for outliers in post-Eddy data for each subject `$studydir/derivatives/dMRI/sub-sID/dwi/preproc/dwi_den_unr_eddy.mif.gz` and decide whether it should be kept or not
- The QC results are stored in `sub-NENAHGRP/qc/squad_quad_cnr/QC_SQUAD.tsv`, specifically `qc_eyeball-postEddy_pass_fail` and given `1=pass`, `0.5=borderline` or `0=fail`
- This column is transferred to `$studydir/derivatives/dMRI/QC_dMRI_pipeline.tsv`

Visualisaton of preprocessed data is done with script `$codedir/dMRI/Visualise_QC_Eddy.sh`

Guidance from [EDDY QC paper](https://www.sciencedirect.com/science/article/pii/S1053811918319451) and the paper on the [dMRI pipeline in dHCP](https://www.sciencedirect.com/science/article/pii/S1053811918304889?via%3Dihub)
#### Response
#### CSD  
#### 5TT 
