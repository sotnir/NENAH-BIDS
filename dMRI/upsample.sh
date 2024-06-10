#!/bin/bash

usage() {
  echo "Usage: $0 [-d data-dir] [-v voxel-size] [-QC qc-file] [-h help] sID"
  echo "Script to upsample DWI data and use it to generate meanb1000 and create brain masks"
  echo ""
  echo "Arguments:"
  echo "  sID              Subject ID (e.g. NENAHC001)"
  echo ""
  echo "Options:"
  echo "  -d / -data-dir   <directory>  The base directory used for output of upsampling files (default: derivatives/dMRI/sub-sID/dwi)"
  echo "  -v / -voxel-size <size>       The voxel size for upsampling (default: 1.25)"
  echo "  -QC <qc-file>                 QC file with entries for the optimal BET f-value (default: \ NENAH_BIDS/QC/QC_dwi.csv)"
  echo "  -h / -help                    Print usage"
  exit 1
}

# default parameters
studydir=$PWD
codedir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#basedir=$studydir/derivatives
voxel_size=1.25
datadir=derivatives/dMRI/sub-sID/dwi
qc_file=$codedir/../QC/QC_dwi.csv

# return usage if no input arguments
if [ $# -eq 0 ]; then
  usage
fi

# command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|-data-dir)
      datadir=$2
      shift 2
      ;;
    -v|-voxel-size)
      voxel_size=$2
      shift 2
      ;;
    -QC)
      qc_file=$2
      shift 2
      ;;
    -h|-help)
      usage
      ;;
    *)
      sID=$1
      shift
      ;;
  esac
done

#  check sub id has been given
if [ -z "$sID" ]; then
  echo "Error: No subject ID provided."
  usage
  exit 1
fi

# # update datadir with subject ID
datadir=derivatives/dMRI/sub-$sID/dwi

# ################ UPSAMPLING ################

# # perform upsampling for the subject
subject_dir="$studydir/$datadir"
# input_file="$subject_dir/dwi_preproc.mif.gz"
# output_file="$subject_dir/dwi_preproc_hires.mif.gz"

# # check input file exists
# if [[ ! -f "$input_file" ]]; then
#   echo "Input file $input_file not found for subject $sID!"
#   exit 1
# fi

# # upsampling
# echo "Upsampling $input_file to voxel size $voxel_size for subject $sID..."
# mrgrid "$input_file" regrid -vox "$voxel_size" "$output_file"


################ MEANB0 AND MEANB1000 GENERATION ################

# generate meanb0 and meanb1000 from the upsampled DWI data


cd $subject_dir

# assign upsampled DWI file
upsampled_dwi="dwi_preproc_hires"


# if [ ! -f meanb0_$upsampled_dwi.mif.gz ]; then
#     dwiextract -shells 0 $upsampled_dwi.mif.gz - | mrmath -force -axis 3 - mean meanb0_$upsampled_dwi.mif.gz
# fi

# if [ ! -f meanb1000_$upsampled_dwi.mif.gz ]; then
#     dwiextract -shells 1000 $upsampled_dwi.mif.gz - | mrmath -force -axis 3 - mean meanb1000_$upsampled_dwi.mif.gz
# fi

# if [ ! -f meanb2600_$upsampled_dwi.mif.gz ]; then
#     dwiextract -shells 2600 $upsampled_dwi.mif.gz - | mrmath -force -axis 3 - mean meanb2600_$upsampled_dwi.mif.gz
# fi



################ BRAIN MASK GENERATION ################

#How do we handle the subjects who do not have optimal BET value?

if [ ! -f "$qc_file" ]; then
  echo "QC file $qc_file not found!"
  exit 1
fi

# {print $NF} takes the value of the last col, maybe bad if we are to add coloumns in qc-file 
# in future
optimal_bet=$(awk -F, -v id="$sID" '$1 == id {print $NF}' "$qc_file")

if [ -z "$optimal_bet" ]; then
  echo "Optimal BET f-value not found for subject $sID in QC file."
  exit 1
fi

echo "Using optimal BET f-value of $optimal_bet for subject $sID"

echo "suddir här $subjectdir här"

# create brain mask
meanb1000_file="$subjectdir/meanb1000_$upsampled_dwi.mif.gz"
mask_file="mask_$upsampled_dwi.mif.gz"
temp_meanb1000="meanb1000tmp.nii.gz"

mrconvert $meanb1000_file $temp_meanb1000
bet $temp_meanb1000 meanb1000tmp_0p${optimal_bet} -R -m -f $optimal_bet

# convert the BET mask to mif format
mrconvert meanb1000tmp_0p${optimal_bet}_mask.nii.gz $mask_file

# clean up temp. files (I assume we are not using these anymore)
#rm meanb1000tmp.nii.gz meanb1000tmp_0p${optimal_bet}_mask.nii.gz

# visual checking (is this needed?)
echo "Visually check the brain mask:"
echo "mrview $meanb1000_file -roi.load $mask_file -roi.opacity 0.5 -mode 2"

echo "Brain mask created for subject $sID at $subject_dir/$mask_file"