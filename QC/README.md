# QC routines for NENAH-BIDS
Routines for assessing data quality in NENAH MRI data

## sMRI
### MRIQC report
- Eye-balling rawdata
- MRIQC output MOREMORE

Decide which T1w to use for the sMRI pipeline\
Update in `QC_MRIQC_anat.tsv`

## fMRI
### MRIQC report
- Eye-balling rawdata\
- MRIQC report output MOREMORE

Update in `QC_MRIQC_func.tsv`

## dMRI
### rawdata 
- Eye-balling rawdata on a per shell basis
- Determine appropriate (motion-free) b0:s in dir-AP and dir-PA to use for TOPUP

Update in `QC_dwi.tsv`

### eddy_qc
Inspect output from EDDY QUAD routine
- Check `preproc/eddy/quad/qc.pdf`
- Inspect for outliers in dwi_post_eddy data

Update in `QC_dwi.tsv`

Guidance from [EDDY QC paper](https://www.sciencedirect.com/science/article/pii/S1053811918319451) and the paper on the [dMRI pipeline in dHCP](https://www.sciencedirect.com/science/article/pii/S1053811918304889?via%3Dihub)
