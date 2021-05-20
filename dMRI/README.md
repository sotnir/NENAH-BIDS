Bash and python scripts for dMRI preprocessing, including:

 - `preprocess.sh`
1. MP-PCA Denoising and Gibbs Unringing 
2. TOPUP and EDDY for motion- and susceptebility image distortion correction. Also QC report
Current implementation - chose a pair of motion-free (non MP-PCA & Gibbs processed) B0s with reverse PE encodings (i.e. dir-AP and dir-PA) and save into /derivatives/dMRI/sub-$sID/preproc/b0APPA.mif.gz => will be input to TOPUP
3. N4 biasfield correction, Normalisation
