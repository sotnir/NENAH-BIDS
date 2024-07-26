#!/bin/bash


#!/bin/bash


usage() {
  echo "Usage: $0 [-d data-dir] [-h help] sID"
  echo "Script to replace the sub-cortical grey matter structure delineations in aparc+aseg.mgz using FSL FIRST and "
  echo "then combine the resulting segmentation-image with the HIPS-THOMAS segmentation of thalamus."
  echo "Arguments:"
  echo "  sID              Subject ID (e.g. NENAHC001)"
  echo ""
  echo "Options:"
  echo "  -d / -data-dir   <directory>  The base directory used for output of upsampling files (default: derivatives/dMRI/sub-sID)"
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
    -h|-help)
      usage
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
T1_image="${studydir}/derivatives/sMRI_fs-segmentation/sub-$sID/mri/T1.mgz"
aparc_aseg_gmfix="${studydir}/derivatives/sMRI_fs-segmentation/sub-$sID/mri/aparc+aseg_gmfix.mif.gz"
left_thomas_segm="${studydir}/derivatives/sMRI_thalamic_thomas/sub-$sID/left/thomasfull.nii.gz"
right_thomas_segm="${studydir}/derivatives/sMRI_thalamic_thomas/sub-$sID/right/thomasrfull.nii.gz"



# temporary files to set thalamus to white matter in aparc+aseg.mgz and then combine it with the left/right hips-thomas segmentation. 
tmp_left_thomas="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_thomas_left.mif"
tmp_right_thomas="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_thomas_right.mif"
tmp_left_right_thomas="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_thomas_full.mif"
tmp_fs_thalamus_is_wm="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_fs_thalamus_is_wm.mif"
tmp_left_mask="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_left_mask.mif"
tmp_right_mask="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_right_mask.mif"
tmp_mask_full="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_full_mask.mif"
tmp_fs_no_thalamus="${studydir}/derivatives/dMRI/sub-$sID/anat/tmp_fs_no_thalamus.mif"

# outputs
combined_segm="${datadir}/anat/aparc+aseg_thomas-thalamic_gmfix.mif.gz"

#### Replace the sub-cortical gray matter structure delineations in aparc+aseg.mgz using FSL FIRST ###
echo ""
echo "Running 'combine_segmentations.sh' for $sID:"
echo ""

if [ ! -f $aparc_aseg_gmfix ]; then
  echo "Replacing sub-cortical gray matter structure delineations using FSL FIRST in 'aparc+aseg.mgz':"
  labelsgmfix $aparc_aseg $T1_image $fs_lut $aparc_aseg_gmfix -sgm_amyg_hipp
  echo ""
else  
  echo "'aparc+aseg_gmfix.mif.gz' already exists for $sID skipping 'labelsgmfix'..."
  echo ""
fi


### Re-label thalamus as white matter in in the FreeSurfer segmented image and then combine it with HIPS-THOMAS image. ###
if [ ! -f $combined_segm ]; then

  echo ""
  echo "Creating temporary mask of left/right HIPS-THOMAS segmentation:"
  mrcalc $left_thomas_segm 0 -gt $tmp_left_mask
  mrcalc $right_thomas_segm 0 -gt $tmp_right_mask
  mrcalc $tmp_left_mask $tmp_right_mask -add $tmp_mask_full
  echo ""

  echo "Creating temporary left/right HIPS-thomas segmentation with increased voxelvalues:"
  mrcalc $left_thomas_segm  14999 -add $tmp_left_mask -mult $tmp_left_thomas
  mrcalc $right_thomas_segm 15011 -add $tmp_right_mask -mult $tmp_right_thomas
  mrcalc $tmp_left_thomas $tmp_right_thomas -add $tmp_left_right_thomas
  echo ""

  echo "Labelling the Thalamus as white matter in FreeSurfers aparc+aseg.mgz"
  labelconvert $aparc_aseg_gmfix $fs_lut $fs_convert $tmp_fs_thalamus_is_wm
  echo ""

  echo "Combining HIPS-THOMAS and FreeSurfer segmentations into aparc+aseg_thomas-thalamic_gmfix.mif.gz:"
  mrcalc $tmp_mask_full 0 -eq $tmp_fs_thalamus_is_wm -mult $tmp_fs_no_thalamus
  mrcalc $tmp_fs_no_thalamus $tmp_left_right_thomas -add $combined_segm
  echo ""

  if [ -f $combined_segm ]; then
    echo "Segmentations combined successfully. Output in /datadir/anat/."
    echo ""
    echo "Removing tmp. files..."
    rm $tmp_left_thomas
    rm $tmp_right_thomas
    rm $tmp_left_right_thomas
    rm $tmp_fs_thalamus_is_wm
    rm $tmp_left_mask
    rm $tmp_right_mask
    rm $tmp_mask_full
    rm $tmp_fs_no_thalamus
    echo ""
  else
    echo "Could not combine segmentations for $sID"
    echo "Keeping tmp. files in /$sID/anat for error-tracking"
    echo ""
  fi
else
  echo "aparc+aseg_thomas-thalamic.mif.gz already exists for $sID"
fi





    


