#!/bin/bash


#!/bin/bash


usage() {
  echo "Usage: $0 [-d data-dir] [-m -mrtrix] [-h help] sID"
  echo "Script to "
  echo ""
  echo "Arguments:"
  echo "  sID              Subject ID (e.g. NENAHC001)"
  echo ""
  echo "Options:"
  echo "  -d / -data-dir   <directory>  The base directory used for output of upsampling files (default: derivatives/dMRI/sub-sID)"
  echo "  -m / -mrtrix                  The PATH to MRTrix3 (default: ../software/mrtrix3)"
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
    -m|-mrtrix)
      MRTRIXHOME=$2
      shift 2
      ;;
    -h|-help)
      usage
      ;;
    -v|-visualize)
      visualisation=1
      shift
      ;;
    *)
      sID=$1
      shift
      ;;
  esac
done


# default params
studydir=$PWD
datadir="${studydir}/derivatives/dMRI/sub-$sID"

# LUTS
fs_lut="$FREESURFER/FreeSurferColorLUT.txt"
fs_convert="${studydir}/code/NENAH-BIDS/label_names/convert_fs_thalamus_to_wm.txt"
thomas_lut="~/software/hipsthomas/Thomas.lut"


# segmentations
aparc_aseg="${studydir}/derivatives/sMRI_fs-segmentation/sub-$sID/mri/aparc+aseg.mgz"
left_thomas_segm="${studydir}/derivatives/sMRI_thalamic_thomas/sub-$sID/left/thomasfull.nii.gz"
right_thomas_segm="${studydir}/derivatives/sMRI_thalamic_thomas/sub-$sID/right/thomasrfull.nii.gz"



#tmp-files
tmp_left_thomas="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_thomas_left.mif"
tmp_right_thomas="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_thomas_right.mif"
tmp_left_right_thomas="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_thomas_full.mif"
tmp_fs_thalamus_is_wm="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_fs_thalamus_is_wm.mif"
tmp_left_mask="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_left_mask.mif"
tmp_right_mask="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_right_mask.mif"
tmp_mask_full="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_full_mask.mif"

tmp_fs_no_thalamus="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_fs_no_thalamus.mif"

# outputs
combined_segm="${datadir}/anat/aparc+aseg_thomas-thalamic.mif.gz" #fyll i här

#aparc_aseg_gmfix="${datadir}/anat/aparc+aseg_gmfix.mif.gz"

### Lägg in combination of left/right thomas från thal_con här ist

#if [ ! -f $aparc_aseg_gmfix ]; then

#fi



if [ ! -f $combined_segm ]; then
  echo "kör"

  mrcalc $left_thomas_segm 0 -gt $tmp_left_mask
  mrcalc $right_thomas_segm 0 -gt $tmp_right_mask
  mrcalc $tmp_left_mask $tmp_right_mask -add $tmp_mask_full

  mrcalc $left_thomas_segm  15000 -add $tmp_left_mask -mult $tmp_left_thomas
  mrcalc $right_thomas_segm 15022 -add $tmp_right_mask -mult $tmp_right_thomas
  
  mrcalc $tmp_left_thomas $tmp_right_thomas -add $tmp_left_right_thomas

  labelconvert $aparc_aseg $fs_lut $fs_convert $tmp_fs_thalamus_is_wm

  mrcalc $tmp_fs_thalamus_is_wm 0 -eq $tmp_mask_full -mult $tmp_fs_no_thalamus
  mrcalc $tmp_fs_no_thalamus $tmp_left_right_thomas -add $combined_segm

fi





    


