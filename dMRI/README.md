Bash and python scripts for dMRI processing, including:

Essentially follows the [BATMAN tutorial](https://osf.io/pm9ba/) and [FBA analysis in MRtrix](https://mrtrix.readthedocs.io/en/latest/fixel_based_analysis/mt_fibre_density_cross-section.html#fibre-density-and-cross-section-multi-tissue-csd)

Datadir is `/derivatives/dMRI/sub-$sID`

### Before start

Make sure your `.bashrc` file contains the paths to all the dependent packages.

- For MRtrix3, add path according to the issue [here](https://github.com/yukaizou2015/NENAH-BIDS/issues/18#issuecomment-877311286).

### Running scripts 

Scripts should be run in the following order:

- preprocess.sh
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
