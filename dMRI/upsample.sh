#!/bin/bash

usage() {
  echo "Usage: $0 [-d data-dir] [-v voxel-size] [-h help] sID"
  echo "Script to upsample DWI data and use it to generate meanb1000 and creating brain mask"
  echo ""
  echo "Arguments:"
  echo "  sID              Subject ID (e.g. NENAHC001)"
  echo ""
  echo "Options:"
  echo "  -d / -data-dir   <directory> The base directory used for output of upsampling files (default: derivatives/dMRI/sub-sID)"
  echo "  -v / -voxel-size <size>      The voxel size for upsampling (default: 1.25)"
  echo "  -h / -help       Print usage"
  exit 1
}

# default parameters
studydir=$PWD
basedir=$studydir/NENAH_BIDS/derivatives
voxel_size=1.25

# return usage if no input arguments
if [ $# -eq 0 ]; then
  usage
fi

# command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|-data-dir)
      basedir=$2
      shift 2
      ;;
    -v|-voxel-size)
      voxel_size=$2
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

################ UPSAMPLING ################

# perform upsampling for the subject
subject_dir="$basedir/dMRI/sub-$sID/dwi"
input_file="$subject_dir/dwi_preproc.mif.gz"
output_file="$subject_dir/dwi_preproc_hires.mif.gz"

# check input file exists
if [[ ! -f "$input_file" ]]; then
  echo "Input file $input_file not found for subject $sID!"
  exit 1
fi

# upsampling
echo "Upsampling $input_file to voxel size $voxel_size for subject $sID..."
mrgrid "$input_file" regrid -vox "$voxel_size" "$output_file"


################ MEANB0 AND MEANB1000 GENERATION ################

# generate meanb0 and meanb1000 from the upsampled DWI data


cd $subject_dir

# assign upsampled DWI file
upsampled_dwi="dwi_preproc_hires"


#Maybe I missheard that we needed meanb0 for something?

if [ ! -f meanb0_$upsampled_dwi.mif.gz ]; then
    dwiextract -shells 0 $upsampled_dwi.mif.gz - | mrmath -force -axis 3 - mean meanb0_$upsampled_dwi.mif.gz
fi

if [ ! -f meanb1000_$upsampled_dwi.mif.gz ]; then
    dwiextract -shells 1000 $upsampled_dwi.mif.gz - | mrmath -force -axis 3 - mean meanb1000_$upsampled_dwi.mif.gz
fi

if [ ! -f meanb2600_$upsampled_dwi.mif.gz ]; then
    dwiextract -shells 2600 $upsampled_dwi.mif.gz - | mrmath -force -axis 3 - mean meanb2600_$upsampled_dwi.mif.gz
fi



################ BRAIN MASK GENERATION ################

# enter QC file and get optimal BET f-value
qc_file="$basedir/../code/NENAH-BIDS/QC/QC_dwi.csv"

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

# create brain mask
meanb1000_file="meanb1000_$upsampled_dwi.mif.gz"
mask_file="mask_$upsampled_dwi.mif.gz"
temp_meanb1000="meanb1000tmp.nii.gz"

mrconvert $meanb1000_file $temp_meanb1000
bet $temp_meanb1000 meanb1000tmp_0p${optimal_bet} -R -m -f $optimal_bet

# convert the BET mask to mif format
mrconvert meanb1000tmp_0p${optimal_bet}_mask.nii.gz $mask_file

# clean up temp. files (I assume we are not using these anymore)
rm meanb1000tmp.nii.gz meanb1000tmp_0p${optimal_bet}_mask.nii.gz

# visual checking (is this needed?)
echo "Visually check the brain mask:"
echo "mrview $meanb1000_file -roi.load $mask_file -roi.opacity 0.5 -mode 2"

echo "Brain mask created for subject $sID at $subject_dir/$mask_file"