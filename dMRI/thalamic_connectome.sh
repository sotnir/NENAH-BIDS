#!/bin/bash


usage() {
  echo "Usage: $0 [-d data-dir] [-m -mrtrix] [-h help] sID"
  echo "Script to "
  echo "Label and convert files is on the GitHub: (LINK)"
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
datadir="${studydir}/derivatives/dMRI/sub-${sID}" 
MRTRIXHOME="../software/mrtrix3"
complete_lut="${studydir}/code/NENAH-BIDS/label_names/lobes_thalamic_LUT.txt"
thalamus_image="${datadir}/anat/thalamus.mif"
thalamus_lobes_image="${datadir}/anat/thalamus_lobes.mif"


# default lobes params
lobes_convert="${MRTRIXHOME}/share/mrtrix3/labelconvert/fs2lobes_cingsep_convert.txt"
lobes_labels="${MRTRIXHOME}/share/mrtrix3/labelconvert/fs2lobes_cingsep_labels.txt"
aparc_aseg="${studydir}/derivatives/sMRI_fs-segmentation/sub-${sID}/mri/aparc+aseg.mgz"
output_lobes_parcels="${datadir}/anat/lobes_parcels.mif"

# default thalamus params divided into left/right
left_convert="${studydir}/code/NENAH-BIDS/label_names/left_convert.txt"
right_convert="${studydir}/code/NENAH-BIDS/label_names/right_convert.txt"
left_labels="${studydir}/code/NENAH-BIDS/label_names/left_labels.txt"
right_labels="${studydir}/code/NENAH-BIDS/label_names/right_labels.txt"
left_thomas_segm_nifty="${studydir}/derivatives/sMRI_thalamic_thomas/sub-${sID}/left/thomasfull.nii.gz"
right_thomas_segm_nifty="${studydir}/derivatives/sMRI_thalamic_thomas/sub-${sID}/right/thomasrfull.nii.gz"

left_output_thalamus_parcels="${datadir}/anat/left_thalamus_parcels.mif"
right_output_thalamus_parcels="${datadir}/anat/right_thalamus_parcels.mif"




### Convert and create necessary files from the HIPS-THOMAS segmentation and the FS-segmentation


# convert lut for lobes 
if [ ! -f $output_lobes_parcels ]; then
    echo "Executing labelconvert for the lobes..."
    labelconvert $aparc_aseg $lobes_convert $lobes_labels $output_lobes_parcels
fi

if [ -f $output_lobes_parcels ]; then
    echo "Label conversion for lobes complete or already done."
else
    echo "Couldn't convert labels or find existing files, exiting..."
    exit
fi

# convert thomas.nii.gz to mrtrix format
left_thomas_segm="${studydir}/derivatives/sMRI_thalamic_thomas/sub-${sID}/left/thomasl.mif"
right_thomas_segm="${studydir}/derivatives/sMRI_thalamic_thomas/sub-${sID}/right/thomasr.mif"

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

# combine the images into one and store in ${datadir}/dwi/connectome/

thalamus_image_dir=$(dirname "$thalamus_image")

if [ ! -d "$thalamus_image_dir" ]; then
    mkdir -p "$thalamus_image_dir"
fi

if [ ! -f $thalamus_image ]; then 
    echo "Combining left and right thalamus --> thalamus.mif in /sub-${sID}/anat/connectome"
    mrcalc $right_output_thalamus_parcels $left_output_thalamus_parcels -add $thalamus_image
else   
    echo "Combined thalamus image already exists"
fi

if [ ! -f $thalamus_lobes_image ]; then
    echo "Combining thalamus.mif with lobes..."
    mrcalc $thalamus_image $output_lobes_parcels -add $thalamus_lobes_image
else
    echo "Combined thalamus and lobes image already exists"
fi



### Create the thalamo-cortical connectome

tract="${datadir}/dwi/tractography/whole_brain_10M_space-anat.tck" 
sift2_weights="${datadir}/dwi/tractography/whole_brain_10M_sift2_space-anat_mu.txt"

output_connectome="${datadir}/dwi/connectome/whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv"
output_assignments_connectome="${datadir}/dwi/connectome/assignment_whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv"

if [ ! -f $output_connectome ]; then
    echo "Creating thalamo-cortical connectome from whole_brain_10M_space-anat_sift2.txt for $sID"
    tck2connectome $tract $thalamus_image $output_connectome -out_assignment $output_assignments_connectome -symmetric -zero_diagonal -scale_invnodevol -tck_weights $sift2_weights

    if [ -f $output_connectome ]; then
        echo "Connectome created successfully!"
    fi
else 
    echo "Connectome already in this directory"
fi





