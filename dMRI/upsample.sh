#!/bin/bash

usage() {
  echo "Usage: $0 [-d data-dir] [-v voxel-size] [-QC qc-file] [-h help] sID"
  echo "Script to upsample DWI data to and use it to generate meanb1000, create brain masks"
  echo "and calculate diffusion tensor and tensor parametric maps (DTI) on upsampled data."
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

# default parameters
studydir=$PWD
codedir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
voxel_size=1.25
datadir=derivatives/dMRI/sub-${sID}
qc_file=$codedir/../QC/QC_dwi.csv


# ################ UPSAMPLING ################

# # perform upsampling for the subject
input_file="$datadir/dwi/dwi_preproc.mif.gz"
output_file="$datadir/dwi/dwi_preproc_hires.mif.gz"

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


cd $datadir/dwi

# assign upsampled DWI file
upsampled_dwi="dwi_preproc_hires"


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

# subjects without optimal BET-value will not be processed
if [ ! -f $mask_file ]; then

  if [ ! -f "$qc_file" ]; then
    echo "QC file $qc_file not found!"
    exit 1
  fi

  # {print $NF} takes the value of the last col, maybe bad if we are to add coloumns to qc-file 
  # in the future
  optimal_bet=$(awk -F, -v id="$sID" '$1 == id {print $NF}' "$qc_file")

  if [ -z "$optimal_bet" ]; then
    echo "Optimal BET f-value not found for subject $sID in QC file."
    exit 1
  fi

  echo "Using optimal BET f-value of $optimal_bet for subject $sID"


  # create brain mask
  meanb1000_file="$subject_dir/meanb1000_$upsampled_dwi.mif.gz"
  mask_file="mask_space-dwi_hires.mif.gz"
  temp_meanb1000="meanb1000tmp.nii.gz"

  mrconvert $meanb1000_file $temp_meanb1000
  bet $temp_meanb1000 meanb1000tmp_0p${optimal_bet} -R -m -f $optimal_bet

  # convert the BET mask to mif format
  mrconvert meanb1000tmp_0p${optimal_bet}_mask.nii.gz $mask_file

  # clean up temp. files
  rm meanb1000tmp.nii.gz meanb1000tmp_0p${optimal_bet}_mask.nii.gz

  # visual checking
  echo "Visually check the brain mask:"
  echo "mrview $meanb1000_file -roi.load $mask_file -roi.opacity 0.5 -mode 2"

  echo "Brain mask created for subject $sID at $subject_dir/$mask_file"

  # Create brain extracted meanb1000
  mrcalc $meanb1000_file $mask_file -mul $subject_dir/meanb1000_brain_$upsampled_dwi.mif.gz
fi


### Calculate diffusion tensor and tensor metrics

cd $datadir/dwi


if [ ! -d dti ]; then mkdir dti; fi

if [ ! -f dti/dt_hires.mif.gz ]; then
    dwiextract -shells 0,1000 $upsampled_dwi.mif.gz - | dwi2tensor -mask mask.mif.gz - dti/dt_hires.mif.gz
    cd dti
    tensor2metric -force -fa fa_hires.mif.gz -adc adc_hires.mif.gz -rd rd_hires.mif.gz -ad ad_hires.mif.gz -vector ev_hires.mif.gz dt_hires.mif.gz
fi

cd $currdir
