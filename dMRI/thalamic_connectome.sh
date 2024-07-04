#!/bin/bash


usage() {
  echo "Usage: $0 [-d data-dir] [-c convert_txt] [-l labels_txt] [-m -mrtrix] [-h help] sID"
  echo "Script to "
  echo ""
  echo "Arguments:"
  echo "  sID              Subject ID (e.g. NENAHC001)"
  echo ""
  echo "Options:"
  echo "  -d / -data-dir   <directory>  The base directory used for output of upsampling files (default: derivatives/dMRI/sub-sID/dwi)"
  echo "  -m / -mrtrix                   The PATH to MRTrix3 (default: ../software/mrtrix3)"
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



# default params
studydir=$PWD
datadir="${studydir}/derivatives" 
MRTRIXHOME="../software/mrtrix3"
complete_lut="${datadir}/sMRI_thalamic_thomas/lobes_thalamic_LUT.txt"
thalamus_image="${datadir}/sMRI_thalamic_thomas/sub-${sID}/connectome/thalamus.mif"
thalamus_lobes_image="${datadir}/sMRI_thalamic_thomas/sub-${sID}/connectome/thalamus_lobes.mif"

# default lobes params
lobes_convert="${MRTRIXHOME}/share/mrtrix3/labelconvert/fs2lobes_cingsep_convert.txt"
lobes_labels="${MRTRIXHOME}/share/mrtrix3/labelconvert/fs2lobes_cingsep_labels.txt"
aparc_aseg="${datadir}/sMRI_fs-segmentation/sub-${sID}/mri/aparc+aseg.mgz"
output_lobes_parcels="${datadir}/sMRI_fs-segmentation/sub-${sID}/mri/${sID}_lobes_parcels.mif"

# default thalamus params divided into left/right
left_convert="${datadir}/sMRI_thalamic_thomas/left_convert.txt"
right_convert="${datadir}/sMRI_thalamic_thomas/right_convert.txt"
left_labels="${datadir}/sMRI_thalamic_thomas/left_labels.txt"
right_labels="${datadir}/sMRI_thalamic_thomas/right_labels.txt"
left_thomas_segm_nifty="${datadir}/sMRI_thalamic_thomas/sub-${sID}/left/thomas.nii.gz"
right_thomas_segm_nifty="${datadir}/sMRI_thalamic_thomas/sub-${sID}/right/thomasr.nii.gz"

left_output_thalamus_parcels="${datadir}/sMRI_thalamic_thomas/sub-${sID}/left/${sID}_left_thalamus_parcels.mif"
right_output_thalamus_parcels="${datadir}/sMRI_thalamic_thomas/sub-${sID}/right/${sID}_right_thalamus_parcels.mif"







# convert lut for lobes 
if [ ! -f $output_lobes_parcels ]; then
    echo "Executing labelconvert for lobes..."
    labelconvert $aparc_aseg $lobes_convert $lobes_labels $output_lobes_parcels
fi

if [ -f $output_lobes_parcels ]; then
    echo "Label conversion for lobes complete or already done."
else
    echo "Couldn't convert labels or find existing files, exiting..."
    exit
fi

# convert thomas.nii.gz to mrtrix format
left_thomas_segm="${datadir}/sMRI_thalamic_thomas/sub-${sID}/left/thomasl.mif"
right_thomas_segm="${datadir}/sMRI_thalamic_thomas/sub-${sID}/right/thomasr.mif"

if [ ! -f $left_thomas_segm ]; then
    mrconvert $left_thomas_segm_nifty $left_thomas_segm
fi

if [ ! -f $right_thomas_segm ]; then
    mrconvert $right_thomas_segm_nifty $right_thomas_segm
fi

# convert lut for left and right thalamus
if [ ! -f $left_output_thalamus_parcels ]; then
    echo "Executing labelconvert for left thalamus..."
    labelconvert $left_thomas_segm $left_convert $left_labels $left_output_thalamus_parcels
fi

if [ ! -f $right_output_thalamus_parcels ]; then
    echo "Executing labelconvert for right thalamus..."
    labelconvert $right_thomas_segm $right_convert $right_labels $right_output_thalamus_parcels
fi

if [ -f $right_output_thalamus_parcels ] && [ -f $left_output_thalamus_parcels ]; then
    echo "Label conversion for left and right thalamus complete or already done."
else
    echo "Couldn't convert labels or find existing files, exiting..."
    exit
fi

# combine the images into one and store in sMRI_thalamic_thomas/sub_id/connectome/

thalamus_image_dir=$(dirname "$thalamus_image")

if [ ! -d "$thalamus_image_dir" ]; then
    mkdir -p "$thalamus_image_dir"
fi

echo "Combining left and right thalamus --> thalamus.mif in /sub-${sID}/connectome"
mrcalc $right_output_thalamus_parcels $left_output_thalamus_parcels -add $thalamus_image

echo "Combining thalamus.mif with lobes..."
mrcalc $thalamus_image $output_lobes_parcels -add $thalamus_lobes_image







