#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Script to preprocess FSL's eddy (via dwifslpreprocess) to include CNR-maps as output 
Only run if dwi_den_unr_eddy.mif.gz exists (i.e. eddy has been run before)
New eddy_quad output is gathered in $datadir/preproc 

Arguments:
  sID    Subject ID   (e.g. NENAHC001) 
Options:
  -threads          Number of threads for parallell processing (default: 18)
  -d / -data-dir <directory> The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help	Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

currdir=$PWD
# check whether the different tools are set and load parameters
studydir=$currdir;
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Defaults
datadir=derivatives/dMRI/sub-$sID
threads=18

shift
while [ $# -gt 0 ]; do
    case "$1" in
 -d|-data-dir)  shift; datadir=$1; ;;
 -threads) shift; threads=$1; ;;
 -h|-help|--help) usage; ;;
 -*) echo "$0: Unrecognized option $1" >&2; usage; ;;
 *) break ;;
    esac
    shift
done


echo dMRI preprocessing subject $sID
script=`basename $0 .sh`

##################################################################################
# 2. TOPUP and EDDY for Motion- and susceptibility distortion correction
cd $datadir/dwi/preproc

scratchdir=dwifslpreproc
eddydir=eddy_cnr

# Do Topup and Eddy with dwipreproc and b0APPA.mif.gz as input
if [ -f dwi_den_unr_eddy.mif.gz ]; then
	dwifslpreproc -scratch $scratchdir \
  -nocleanup \
  -rpe_header -se_epi b0APPA.mif.gz \
  -eddy_slspec $studydir/sequences/slspec_NENAH_64_interleaved_slices.txt -align_seepi \
	-topup_options " --iout=field_mag_unwarped" \
	-eddy_options " --cnr_maps --slm=linear --repol --mporder=16 --s2v_niter=10 --s2v_interp=trilinear --s2v_lambda=1 " \
	-eddyqc_all $eddydir \
  -nthreads $threads \
  dwi_den_unr.mif.gz \
	dwi_den_unr_eddy-cnr.mif.gz;
  # or use -rpe_pair combo: dwifslpreproc DWI_in.mif DWI_out.mif -rpe_pair -se_epi b0_pair.mif -pe_dir ap -readout_time 0.72 -align_seepi
fi

# Now cleanup by transferring relevant files to topup folder and deleting scratch folder

mv $eddydir/eddy_cnr_maps.nii.gz eddy/.
mv $eddydir/quad ../../qc/eddy_quad_cnr
rm -rf $scratchdir

cd $currdir
