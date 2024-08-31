#!/bin/bash


usage() {
  echo "Usage: $0 [-d data-dir] [-m -mrtrix] [-h help] sID"
  echo "Script to "
  echo "1) generate thalamo-cortical connectivity matrix (thalamus to lobes)"
  echo "2) generate a connectivity matrix where the value of connectivity is the mean FA."
  echo "This is done by re-mapping the outputs of FreeSurfer segmentation of the lobes and the HIPS-THOMAS segmentation of thalamus, and combining into a single parcellation image."
  echo "Requires that segmentation of thalamus using HIPS-THOMAS has been performed and that fa_hires has been created using dti.sh"
  echo "The LUTs and corresponding labels used for mapping the parcellation images is on the GitHub: https://github.com/sotnir/NENAH-BIDS/tree/RioPhillips-branch/label_names"
  echo ""
  echo "Arguments:"
  echo "  sID              Subject ID (e.g. NENAHC001)"
  echo ""
  echo "Options:"
  echo "  -d / -data-dir   <directory>  The base directory used for output of upsampling files (default: derivatives/dMRI/sub-sID)"
  echo "  -m / -mrtrix                  The PATH to MRTrix3 (default: ../software/mrtrix3)"
  echo "  -h / -help                    Print usage"
  echo "  -v / -visualize               Will generate a colored thalamus-lobes parcellation image, a mesh-file (.obj) for viewing nodes as 3D sections of the brain and a track file"
  echo "                                which allows the display of edges as streamlines or streamtubes. Visualization files will be but in the /dwi/connectome/visualisation/ folder."
  echo "                                This is recommended to be used on one or few subjects only, on as-needed basis."
  exit 1
}


# return usage if no input arguments
if [ $# -eq 0 ]; then
  usage
fi


# default visualisation param
visualisation=0

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

#  check sub id has been given
if [ -z "$sID" ]; then
  echo "Error: No subject ID provided."
  usage
  exit 1
fi



# default params
studydir=$PWD
datadir="${studydir}/derivatives/dMRI/sub-${sID}" 

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
##

if [ ! -f "${datadir}/dwi/connectome/whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv" ];then

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
        echo "Converting nii.gz thomas segmentation files to .mif"
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
        echo "Creating thalamo-cortical connectome from whole_brain_10M_space-anat.tck with Sift2 weights for $sID"
        echo ""
        tck2connectome -symmetric -zero_diagonal -scale_invnodevol $tract $thalamus_lobes_image $output_connectome -out_assignment $output_assignments_connectome -tck_weights_in $sift2_weights

        if [ -f $output_connectome ]; then
            echo "Connectome created successfully!"
            echo ""
        else   
            echo "### Failed to create connectome for $sID ###"
            echo ""
        fi
    else 
        echo "Connectome already in this directory"
        echo ""
    fi
else
    echo "Default thalamic connectome exists for $sID"
    echo "Starting with mean FA connectome..."
    echo ""
fi


### Generating connectome matrix where the value of connectivity is the "mean FA"
if [ ! -f $mean_FA_connectome ]; then
    ## Parameters för mean_FA connectome
    mean_FA_per_streamline="${datadir}/dwi/dti/mean_FA_per_streamline.csv"
    mean_FA_connectome="${datadir}/dwi/connectome/whole_brain_10M_space-anat_mean_FA_connectome.csv"
    fa_dwi2anat_transform="${datadir}/xfm/dwi_2_t1w_mrtrix-bbr.mat"
    tract="${datadir}/dwi/tractography/whole_brain_10M_space-anat.tck"
    nodes=$thalamus_lobes_image
    fa_hires_dwi="${datadir}/dwi/dti/fa_hires.mif.gz"



    echo ""
    echo "Generating connectome with mean FA for $sID:"
    echo ""

    if [ ! -f $fa_hires_dwi ]; then
        echo "### Cannot find FA hires file for $sID, exiting... ###"
        exit
    fi

    # transform FA to anatomical space and perform connectome analysis
    echo "Transforming FA to anatomical space and creating connectome for $sID by piping it through tcksample and tck2connectome:"
    mrtransform $fa_hires_dwi -linear $fa_dwi2anat_transform - | tcksample $tract - $mean_FA_per_streamline -stat_tck mean
    tck2connectome $tract $nodes $mean_FA_connectome -scale_file $mean_FA_per_streamline -stat_edge mean

    if [ -f "$mean_FA_connectome" ]; then
        echo "Mean FA connectome generated successfully!"
        echo ""
    else
        echo "Connectome analysis failed for $sID, exiting..."
        exit
    fi
else
    echo "Mean FA connectome already exists for $sID"
    echo ""
fi



### Create visualisation
if [ $visualisation = 1 ]; then
    visualisation_dir="${datadir}/dwi/connectome/visualisation/"
    nodes=$thalamus_lobes_image
    vis_nodes="${visualisation_dir}/vis_thalamus_lobes.mif"
    mesh_file="${visualisation_dir}/mesh_thalamus_lobes.obj"
    tract="${datadir}/dwi/tractography/whole_brain_10M_space-anat.tck"
    assignments="${datadir}/dwi/connectome/assignment_whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv"
    exemplars="${visualisation_dir}/exemplars.tck"


    if [ ! -d "$visualisation_dir" ]; then
        mkdir -p "$visualisation_dir"
    fi

    if [ ! -f "$vis_nodes"]; then
        echo "Generating colored thalamus-lobes parcellation image:"
        label2colour $nodes $vis_nodes
        echo ""
    else
        echo "Colored thalamus-lobes parcellation image already exists for $sID"
        echo ""
    fi

    if [ ! -f "$$mesh_file"]; then
        echo "Creating mesh-file (.obj) for thalamus-lobes parcellation image:"
        label2mesh $nodes $mesh_file
        echo ""
    else
        echo "mesh-file already exists for $sID"
        echo ""
    fi

    if [ ! -f "$exemplars"]; then
        echo "Generating track file for visualising edges as streamlines or streamtubes (exemplars.tck):"
        connectome2tck $tract $assignments $exemplars -files single -exemplars $nodes
        echo ""
    else
        echo "exemplars.tck already exists for $sID"
        echo ""
    fi

    echo "If successfull, the three files are in the /dwi/connectome/visualisation/ folder."






fi