#!/bin/bash
# NENAH study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Visalisation of FreeSurfer segmentation output for QC
Arguments:
  sID				Subject ID (e.g. NENAH001)
Options:
  voltype			Type of volumes to visualize. If no value is assigned (default), the discrete segmentation volumes are visualised. Options are:
     HBT                        Subdivide hippocampus into head, body, and tail
     FS60                       No subdivision of hippocampus, mimicking FreeSurfer 6.0
     CA                         To visualize the volumes of CA subfields
  -freesurfer_subject_folder	Path to FreeSurfer folder (default: deriatives/sMRI_fs-segmentation/sub-\$sID)  
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

# Defaults
currdir=`pwd`
freesurfer_subject_folder=derivatives/sMRI_fs-segmentation/sub-$sID

shift
while [ $# -gt 0 ]; do
    case "$1" in
	-freesurfer) shift; freesurfer=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
if [ ! -f $tw1 ]; then tw1=""; fi

# Strange the pial surfaces get the suffix .T1 (e.g. lh.pial.T1)
# sort this by chosing the available one for rh/lh
if [ -f $freesurfer_subject_folder/surf/rh.pial.T1 ]; then
    rhpial=rh.pial.T1
else
    rhpial=rh.pial
fi
if [ -f $freesurfer_subject_folder/surf/lh.pial.T1 ]; then
    lhpial=lh.pial.T1
else
    lhpial=lh.pial
fi

# Visualisation with FreeSurfer's freeview (taken from https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/OutputData_freeview)
#To verify that FreeSurfer did a good job, you will want to check:
# - Whether the surfaces accurately follow the gray matter and white matter boundaries.
# - Whether the aseg accurately follows the subcortical intensity boundaries.

# Note that [lr]h.hippoAmygLabels-T1.v21.mgz and [lr]h.hippoAmygLabels-T1.v21.[hierarchy].mgz cover only a patch around the hippocampus, 
# at a higher resolution than the input image. The segmentation and the image are defined in the same physical coordinates, 
# so you can visualize them simultaneously with (run from the subject's mri directory)

if [ -f $2 ]; then
freeview -v $freesurfer_subject_folder/mri/nu.mgz \
         -v $freesurfer_subject_folder/mri/lh.hippoAmygLabels-T1.v21.mgz:colormap=lut \
         -v $freesurfer_subject_folder/mri/rh.hippoAmygLabels-T1.v21.mgz:colormap=lut
else
freeview -v $freesurfer_subject_folder/mri/nu.mgz \
         -v $freesurfer_subject_folder/mri/lh.hippoAmygLabels-T1.$2.v21.mgz:colormap=lut \
         -v $freesurfer_subject_folder/mri/rh.hippoAmygLabels-T1.$2.v21.mgz:colormap=lut
fi


