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
thomas_lut="${studydir}/code/NENAH-BIDS/label_names/thomas_lut_excluding_RBGA.txt"

# default lobes params
lobes_convert="${studydir}/code/NENAH-BIDS/label_names/fs2lobes_cingsep_convert_excl_thalamus.txt"
lobes_labels="${MRTRIXHOME}/share/mrtrix3/labelconvert/fs2lobes_cingsep_labels.txt"
aparc_aseg="${studydir}/derivatives/sMRI_fs-segmentation/sub-${sID}/mri/aparc+aseg.mgz"
FS_LUT="${FREESURFER_HOME}/FreeSurferColorLUT.txt"
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
    labelconvert $aparc_aseg $FS_LUT $lobes_convert $output_lobes_parcels
    if [ -f $output_lobes_parcels ]; then
        echo "Labelconvert for lobes successfull!"
    fi
else
    echo "Label conversion for lobes already done"
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
    labelconvert $left_thomas_segm  $thomas_lut $left_convert $left_output_thalamus_parcels
fi

if [ ! -f $right_output_thalamus_parcels ]; then
    echo "Executing labelconvert for right thalamus..."
    labelconvert $right_thomas_segm $thomas_lut $right_convert $right_output_thalamus_parcels
    echo ""
fi

if [ -f $right_output_thalamus_parcels ] && [ -f $left_output_thalamus_parcels ]; then
    echo "Label conversion for left and right thalamus complete or already done."
else
    echo "Couldn't convert labels or find existing files, exiting..."
    exit
fi

# combine the images into one and store in ${datadir}/anat/

# temp files 
thalamus_image_tmp="${datadir}/anat/tmp_thalamus.mif"
thalamus_lobes_tmp="${datadir}/anat/tmp_thalamus_lobes.mif"


if [ ! -f $thalamus_lobes_image ]; then 
    echo "Creating thalamus_lobes.mif image in /sub-$sID/anat"
    echo ""
    echo ""
    echo "Combining left and right thalamus --> thalamus.mif"
    mrcalc $right_output_thalamus_parcels $left_output_thalamus_parcels -add $thalamus_image_tmp
    echo ""
    echo ""Combining thalamus.mif with lobes... --> tmp_thalamus_lobes.mif""
    mrcalc $tmp_thalamus $output_lobes_parcels -add $thalamus_lobes_tmp
    echo ""
    echo "Converting tmp_thalamus_lobes.mif to mrview-friendly format (float --> integer)"
    mrconvert -datatype uint32 $thalamus_lobes_tmp $thalamus_lobes_image
    echo ""
    echo "Removing temporary files:"
    rm $thalamus_image_tmp
    rm $thalamus_lobes_tmp
    echo ""
    if [ -f $thalamus_lobes_image ]; then
        echo "Successfully created thalamus_lobes.mif for $sID"
    fi
else   
    echo "The file thalamus_lobes.mif already exists for $sID!"
fi






### Create the thalamo-cortical connectome

tract="${datadir}/dwi/tractography/whole_brain_10M_space-anat.tck" 
sift2_weights="${datadir}/dwi/tractography/whole_brain_10M_space-anat_sift2.txt"

output_connectome="${datadir}/dwi/connectome/whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv"
output_assignments_connectome="${datadir}/dwi/connectome/assignment_whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv"

connectome_dir=$(dirname "$output_connectome")

if [ ! -d "$connectome_dir" ]; then  
    mkdir -p "$connectome_dir"
fi


if [ ! -f $output_connectome ]; then
    echo "Creating thalamo-cortical connectome from whole_brain_10M_space-ant.tck with Sift2 weights for $sID"
    echo ""
    tck2connectome -symmetric -zero_diagonal -scale_invnodevol $tract $thalamus_lobes_image $output_connectome -out_assignment $output_assignments_connectome -tck_weights_in $sift2_weights

    if [ -f $output_connectome ]; then
        echo "Connectome created successfully!"
    else   
        echo "### Failed to create connectome for $sID ###"
    fi
else 
    echo "Connectome already in this directory"
fi


### 




