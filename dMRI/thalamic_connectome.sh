#!/bin/bash


usage() {
  echo "Usage: $0 [-d data-dir] [-m -mrtrix] [-h help] sID"
  echo "Script to "
  echo "1) generate thalamo-cortical connectivity matrix (thalamus to lobes)"
  echo "2) generate a connectivity matrix where the value of connectivity is the mean FA."
  echo "This is done by re-mapping the outputs of FreeSurfer segmentation of the lobes and the HIPS-THOMAS segmentation of thalamus, and combining into a single parcellation image."
  echo "Requires that segmentation of thalamus using HIPS-THOMAS has been performed and that fa_hires has been generated in upsample.sh"
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
  echo "                                This is recommended to be used on one or few subjects only since its very resource-heavy."
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
thalamus_lobes_image="${datadir}/anat/fs_thomas-thalamic_2_fs-lobes_thomas-thalamic-nuclear-groups_aparc+aseg_thomas-thalamic.mif.gz"
ctx_thalamus_image="${datadir}/anat/fs_thomas-thalamic_2_fs-ctx_thomas-thalamic-nuclear-groups_aparc+aseg_thomas-thalamic.mif.gz"
full_fs_thalamus_image="${datadir}/anat/whole_mapped_aparc+aseg_thomas-thalamic.mif.gz"
nuclear_groups_thalamus="${datadir}/anat/fs_thomas-thalamic_2_fs_thomas-thalamic-nuclear-groups_aparc+aseg_thomas-thalamic.mif.gz"

### Create a fs-ctx_thomas-thalamic-nuclear-groups connectome in the network between the FS's cortical parcellations and the HIPS-THOMAS nuclear groups
tract="${datadir}/anat/tractography/whole_brain_10M_space-anat.tck" 
sift2_weights="${datadir}/anat/tractography/whole_brain_10M_space-anat_sift2.txt"

output_connectome="${datadir}/anat/connectome/whole_brain_10M_sift2_space-anat_fs-ctx_thomas-thalamic-nuclear-groups_connectome.csv"
output_assignments_connectome="${datadir}/anat/connectome/assignment_whole_brain_10M_sift2_space-anat_fs-ctx_thomas-thalamic-nuclear-groups_connectome.csv"

connectome_dir=$(dirname "$output_connectome")

if [ ! -d "$connectome_dir" ]; then  
    mkdir -p "$connectome_dir"
fi


if [ ! -f $output_connectome ]; then
    echo "Creating fs-ctx-thomas-thalamic-nuclear-groups connectome from whole_brain_10M_space-anat.tck with Sift2 weights for $sID"
    echo ""
    tck2connectome -symmetric -zero_diagonal -scale_invnodevol $tract $ctx_thalamus_image $output_connectome -out_assignment $output_assignments_connectome -tck_weights_in $sift2_weights

    if [ -f $output_connectome ]; then
        echo "Connectome created successfully!"
        echo ""
    else   
        echo "### Failed to create connectome for $sID ###"
        echo ""
    fi
else
    echo "The connectome exists for $sID"
    echo "Starting with mean FA connectome..."
    echo ""
fi
### Create a fs_thomas-thalamic-nuclear-groups connectome with HIPS-THOMAS segmentation into "medial", "posterior", "lateral" and "anterior" nuclear groups

output_connectome="${datadir}/anat/connectome/whole_brain_10M_sift2_space-anat_fs_thomas-thalamic-nuclear-groups_connectome.csv"
output_assignments_connectome="${datadir}/anat/connectome/assignment_whole_brain_10M_sift2_space-anat_fs_thomas-thalamic-nuclear-groups_connectome.csv"

connectome_dir=$(dirname "$output_connectome")

if [ ! -d "$connectome_dir" ]; then  
    mkdir -p "$connectome_dir"
fi


if [ ! -f $output_connectome ]; then
    echo "Creating fs_thomas-thalamic-nuclear-groups connectome from whole_brain_10M_space-anat.tck with Sift2 weights for $sID"
    echo ""
    tck2connectome -symmetric -zero_diagonal -scale_invnodevol $tract $nuclear_groups_thalamus $output_connectome -out_assignment $output_assignments_connectome -tck_weights_in $sift2_weights

    if [ -f $output_connectome ]; then
        echo "Connectome created successfully!"
        echo ""
    else   
        echo "### Failed to create connectome for $sID ###"
        echo ""
    fi
else
    echo "The connectome exists for $sID"
    echo "Starting with mean FA connectome..."
    echo ""
fi
### Create the full FreeSurfer + HIPS-Thomas connectome

output_connectome="${datadir}/anat/connectome/whole_brain_10M_sift2_space-anat_fs_thalamus_connectome.csv"
output_assignments_connectome="${datadir}/anat/connectome/assignment_whole_brain_10M_sift2_space-anat_fs_thalamus_connectome.csv"

connectome_dir=$(dirname "$output_connectome")

if [ ! -d "$connectome_dir" ]; then  
    mkdir -p "$connectome_dir"
fi


if [ ! -f $output_connectome ]; then
    echo "Creating fs-thalamus connectome from whole_brain_10M_space-anat.tck with Sift2 weights for $sID"
    echo ""
    tck2connectome -symmetric -zero_diagonal -scale_invnodevol $tract $full_fs_thalamus_image $output_connectome -out_assignment $output_assignments_connectome -tck_weights_in $sift2_weights

    if [ -f $output_connectome ]; then
        echo "Connectome created successfully!"
        echo ""
    else   
        echo "### Failed to create connectome for $sID ###"
        echo ""
    fi
else
    echo "The connectome exists for $sID"
    echo "Starting with mean FA connectome..."
    echo ""
fi

### Create the thalamo-lobes connectome

output_connectome="${datadir}/anat/connectome/whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome_2.csv"
output_assignments_connectome="${datadir}/anat/connectome/assignment_whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome_2.csv"

connectome_dir=$(dirname "$output_connectome")

if [ ! -d "$connectome_dir" ]; then  
    mkdir -p "$connectome_dir"
fi


if [ ! -f $output_connectome ]; then
    echo "Creating thalamus-lobes connectome from whole_brain_10M_space-anat.tck with Sift2 weights for $sID"
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
    echo "The connectome exists for $sID"
    echo "Starting with mean FA connectome..."
    echo ""
fi


### Generating connectome matrix where the value of connectivity is the "mean FA"

mean_FA_connectome="${datadir}/anat/connectome/whole_brain_10M_space-anat_mean_FA_connectome.csv"
if [ ! -f $mean_FA_connectome ]; then
    ## Parameters för mean_FA connectome
    mean_FA_per_streamline="${datadir}/dwi/dti/mean_FA_per_streamline.csv"
    fa_dwi2anat_transform="${datadir}/xfm/dwi_2_t1w_mrtrix-bbr.mat"
    tract="${datadir}/anat/tractography/whole_brain_10M_space-anat.tck"
    nodes=$thalamus_lobes_image
    fa_hires_dwi="${datadir}/dwi/dti/fa_hires.mif.gz"



    echo ""
    echo "Generating connectome with mean FA for $sID:"
    echo ""

    if [ ! -f $fa_hires_dwi ]; then
        echo "### Cannot find FA hires file for $sID, exiting... ###"
        exit
    fi

    # transform FA to anatomical space and perform connectome generation
    echo "Transforming FA to anatomical space and creating connectome for $sID by piping it through tcksample and tck2connectome:"
    mrtransform $fa_hires_dwi -linear $fa_dwi2anat_transform - | tcksample $tract - $mean_FA_per_streamline -stat_tck mean
    tck2connectome $tract $nodes $mean_FA_connectome -scale_file $mean_FA_per_streamline -stat_edge mean

    if [ -f "$mean_FA_connectome" ]; then
        echo "Mean FA connectome generated successfully!"
        echo ""
    else
        echo "Connectome generation failed for $sID, exiting..."
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

    if [ ! -f "$vis_nodes" ]; then
        echo "Generating colored thalamus-lobes parcellation image:"
        label2colour $nodes $vis_nodes
        echo ""
    else
        echo "Colored thalamus-lobes parcellation image already exists for $sID"
        echo ""
    fi

    if [ ! -f "$$mesh_file" ]; then
        echo "Creating mesh-file (.obj) for thalamus-lobes parcellation image:"
        label2mesh $nodes $mesh_file
        echo ""
    else
        echo "mesh-file already exists for $sID"
        echo ""
    fi

    if [ ! -f "$exemplars" ]; then
        echo "Generating track file for visualising edges as streamlines or streamtubes (exemplars.tck):"
        connectome2tck $tract $assignments $exemplars -files single -exemplars $nodes
        echo ""
    else
        echo "exemplars.tck already exists for $sID"
        echo ""
    fi

    echo "If successfull, the three files are in the /dwi/connectome/visualisation/ folder."
fi



