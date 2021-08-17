Bash and python scripts for dMRI preprocessing, including:

 - `preprocess.sh`
 - `mrtrix3_export_keyval_json.sh`: a script that calls `mrinfo` from MRtrix3 to extract keyval (e.g. SliceTiming) into json file

Datadir is /derivatives/dMRI/sub-$sID

Performs:
1. MP-PCA Denoising and Gibbs Unringing 
2. TOPUP and EDDY for motion- and susceptebility image distortion correction. 
- Current implementation - chose a pair of motion-free (non MP-PCA & Gibbs processed) B0s with reverse PE encodings (i.e. dir-AP and dir-PA) and save into /derivatives/dMRI/sub-$sID/preproc/b0APPA.mif.gz => will be input to TOPUP
- QC report in /derivatives/dMRI/sub-$sID/preproc/eddy/quad
3. N4 biasfield correction, Normalisation
