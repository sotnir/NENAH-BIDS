Bash and python scripts for dMRI processing, including:

Essentially follows the [BATMAN tutorial](https://osf.io/pm9ba/)

Datadir is `/derivatives/dMRI/sub-$sID`

Run scripts in the following order:

- preprocess.sh
- response.sh
- csd.sh
- normalisation.sh

Need 5TT from sMRI
- registration.sh
- 5tt.sh

- tractography.sh
- connectome.sh
