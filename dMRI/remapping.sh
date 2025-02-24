#!/bin/bash


#usage() {
#}


# return usage if no input arguments
#if [ $# -eq 0 ]; then
#  usage
#fi


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

# This is done by re-mapping the outputs of FreeSurfer segmentation of the lobes and the HIPS-THOMAS segmentation of thalamus, and combining into a single parcellation image.
# Requires that segmentation of thalamus using HIPS-THOMAS has been performed and that fa_hires has been generated in upsample.sh
# The LUTs and corresponding labels used for mapping the parcellation images is on the GitHub: https://github.com/sotnir/NENAH-BIDS/tree/RioPhillips-branch/label_names

# default params
studydir=$PWD
datadir="${studydir}/derivatives/dMRI/sub-${sID}" 
combined_segm="${datadir}/anat/aparc+aseg_thomas-thalamic.mif.gz"
lut_in="${studydir}/code/NENAH-BIDS/label_names/fs_thomas-thalamic_LUT.txt"



### Combining whole-brain FreeSurfer aparc+aseg.mgz and the left/right HIPS-Thomas segmantion of thalamus into one parcellation image with various remapping steps. 
if [ ! -f $thalamus_lobes_image ];then
    ## Thalamus Parameters ###
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

    echo ""
    echo "#### Running thalamic_connectome.sh for $sID: ####"
    echo ""

    ### Convert and create necessary files from the HIPS-THOMAS segmentation and the FS-segmentation


    # convert lut for lobes 
    if [ ! -f $output_lobes_parcels ]; then
        echo "Executing labelconvert for the lobes:"
        labelconvert $aparc_aseg $FS_LUT $lobes_convert $output_lobes_parcels
        echo ""
        if [ -f $output_lobes_parcels ]; then
            echo "Labelconvert for lobes successfull!"
            echo ""
        else    
            echo "### ERROR: Labelconvert for lobes could not be done, exiting... ###"
            exit
        fi
    else
        echo "Label conversion for lobes already done"
        echo ""
    fi

    # convert thomas.nii.gz to mrtrix format
    left_thomas_segm="${studydir}/derivatives/sMRI_thalamic_thomas/sub-${sID}/left/thomasl.mif"
    right_thomas_segm="${studydir}/derivatives/sMRI_thalamic_thomas/sub-${sID}/right/thomasr.mif"

    if [ -f $left_thomas_segm ] && [ -f $right_thomas_segm ]; then
        echo "thomasl.mif and thomasr.mif already exists for $sID, skipping convert step..."
        echo ""
    else
        echo "Converting .nii.gz thomas segmentation files to .mif"
        echo ""
    fi

    if [ ! -f $left_thomas_segm ]; then
        mrconvert $left_thomas_segm_nifty $left_thomas_segm
    fi

    if [ ! -f $right_thomas_segm ]; then
        mrconvert $right_thomas_segm_nifty $right_thomas_segm
    fi

    # convert lut for left and right thalamus

    if [ -f $right_output_thalamus_parcels ] && [ -f $left_output_thalamus_parcels ]; then
        echo "Label conversion for left and right thalamus already done."
        echo ""
    fi


    if [ ! -f $left_output_thalamus_parcels ]; then
        echo "Executing labelconvert for left thalamus..."
        labelconvert $left_thomas_segm  $thomas_lut $left_convert $left_output_thalamus_parcels
        if [ -f $left_output_thalamus_parcels ]; then
            echo "Labelconvert for left thalamus successful!"
            echo ""
        else    
            echo "Labelconvert for left thalamus could not be performed for $sID, exiting..."
            exit
        fi
    fi

    if [ ! -f $right_output_thalamus_parcels ]; then
        echo "Executing labelconvert for right thalamus..."
        labelconvert $right_thomas_segm $thomas_lut $right_convert $right_output_thalamus_parcels
        if [ -f $right_output_thalamus_parcels ]; then
            echo "Labelconvert for right thalamus successful!"
            echo ""
        else
            echo "Labelconvert for right thalamus could not be performed for $sID, exiting..."
            exit
        fi
    fi


    # combine the images into one and store in ${datadir}/anat/

    # temp file
    thalamus_lobes_tmp="${datadir}/anat/tmp_thalamus_lobes.mif"


    if [ ! -f $thalamus_lobes_image ]; then 
        echo "Creating thalamus_lobes.mif image in /sub-$sID/anat"
        echo ""
        echo ""
        echo "Combining left and right thalamus --> thalamus.mif"
        mrcalc $right_output_thalamus_parcels $left_output_thalamus_parcels -add $thalamus_image
        echo ""
        echo "Combining thalamus.mif with lobes... --> tmp_thalamus_lobes.mif"
        mrcalc $thalamus_image 0 -gt $thalamus_image $output_lobes_parcels -if $thalamus_lobes_tmp
        echo ""
        echo "Converting tmp_thalamus_lobes.mif to mrview-friendly format (float --> integer)"
        mrconvert -datatype uint32 $thalamus_lobes_tmp $thalamus_lobes_image
        echo ""
        echo "Removing temporary file..."
        rm $thalamus_lobes_tmp
        echo ""
        if [ -f $thalamus_lobes_image ]; then
            echo "Successfully created thalamus_lobes.mif for $sID"
            echo ""
        else
            echo "### ERROR: Could not create thalamus_lobes.mif for $sID, exiting... ###"
            exit
        fi
    fi
else   
    echo "The file thalamus_lobes.mif already exists for $sID!"
fi


### Remap the full FreeSurfer + HIPS-Thomas images. 



whole_parcellation_image_out="${datadir}/anat/whole_mapped_aparc+aseg_thomas-thalamic.mif.gz"

if [ ! -f $whole_parcellation_image_out ]; then

    lut_out="${studydir}/code/NENAH-BIDS/label_names/fs_thomas-thalamic_LUT-mrtrix3.txt"
    labelconvert $combined_segm $lut_in $lut_out $whole_parcellation_image_out
    
fi

###  Remap FreeSurfer + HIPS-Thomas nuclear groups (medial, posterior, lateral, anterior)

nuclear_groups_parcellation_image_out="${datadir}/anat/fs_thomas-thalamic_2_fs_thomas-thalamic-nuclear-groups_aparc+aseg_thomas-thalamic.mif.gz"

if [ ! -f $nuclear_groups_parcellation_image_out ]; then
    lut_out="${studydir}/code/NENAH-BIDS/label_names/fs_thomas-thalamic_2_fs_thomas-thalamic-nuclear-groups_convert-mrtrix3.txt"
    labelconvert $combined_segm $lut_in $lut_out $nuclear_groups_parcellation_image_out
fi

### Remap targeting FreeSurfer cortex + HIPS-Thomas nuclear groups

ctx_nucleargroups_parcellation_image_out="${datadir}/anat/fs_thomas-thalamic_2_fs-ctx_thomas-thalamic-nuclear-groups_aparc+aseg_thomas-thalamic.mif.gz"

if [ ! -f $ctx_nucleargroups_parcellation_image_out ]; then

    lut_out="${studydir}/code/NENAH-BIDS/label_names/fs_thomas-thalamic_2_fs-ctx_thomas-thalamic-nuclear-groups_convert-mrtrix3.txt"
    labelconvert $combined_segm $lut_in $lut_out $ctx_nucleargroups_parcellation_image_out
fi

### Remap the FreeSurfer segmentation of lobes + HIPS-Thomas nuclear groups 

thalamus_lobes_parcellation_image_out="${datadir}/anat/fs_thomas-thalamic_2_fs-lobes_thomas-thalamic-nuclear-groups_aparc+aseg_thomas-thalamic.mif.gz"

if [ ! -f $thalamus_lobes_parcellation_image_out ]; then
    lut_out="${studydir}/code/NENAH-BIDS/label_names/fs_thomas-thalamic_2_fs-lobes_thomas-thalamic-nuclear-groups_convert-mrtrix3.txt"
    labelconvert $combined_segm $lut_in $lut_out $thalamus_lobes_parcellation_image_out
fi



