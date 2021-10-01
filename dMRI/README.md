Bash and python scripts for dMRI processing, including:

Essentially follows the [BATMAN tutorial](https://osf.io/pm9ba/)

Datadir is `/derivatives/dMRI/sub-$sID`

Run scripts in the following order:

- preprocess.sh
- registration.sh
- csd.sh
- tractography.sh
- connectome.sh


**preprocess.sh**

Performs:
1. MP-PCA Denoising and Gibbs Unringing 
2. TOPUP and EDDY for motion- and susceptebility image distortion correction. 
- Current implementation - chose a pair of motion-free (non MP-PCA & Gibbs processed) B0s with reverse PE encodings (i.e. dir-AP and dir-PA) and save into `/derivatives/dMRI/sub-$sID/preproc/b0APPA.mif.gz` => will be input to TOPUP
- QC report in /derivatives/dMRI/sub-$sID/preproc/eddy/quad
3. N4 biasfield correction, Normalisation (individual)
