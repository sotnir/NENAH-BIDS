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
echo "QC of FreeSurfer segmentation for $sID"
echo To verify that FreeSurfer did a good job, you will want to check:
echo Whether the surfaces accurately follow the gray matter and white matter boundaries.
echo Whether the aseg accurately follows the subcortical intensity boundaries.

freeview -v \
	 $freesurfer_subject_folder/mri/T1.mgz \
	 $freesurfer_subject_folder/mri/wm.mgz \
	 $freesurfer_subject_folder/mri/brainmask.mgz \
	 $freesurfer_subject_folder/mri/aseg.mgz:colormap=lut:opacity=0.2 \
	 -f $freesurfer_subject_folder/surf/lh.white:edgecolor=blue \
	 $freesurfer_subject_folder/surf/$lhpial:edgecolor=red \
	 $freesurfer_subject_folder/surf/rh.white:edgecolor=blue \
	 $freesurfer_subject_folder/surf/$rhpial:edgecolor=red




