#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID [options]
Transform FreeSurfer segmentation into dMRI space
Create 5tt image from FreeSurfer segmentation
and transform into dMRI or anatomical space (requires that registration.sh has been run to create transformation between T1w <-> dMRI)

Arguments:
  sID				Subject ID (e.g. NENAHC012) 
Options:
  -segm				Segmentation from FreeSurfer (default: derivatives/sMRI_fs-segmentation/sub-sID/mri/aparc+aseg.mgz) 
  -space      Choose whether output to dwi-space or anat-space (default: anat)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1
shift; 

studydir=`pwd`

# Defaults
segm=derivatives/sMRI_fs-segmentation/sub-$sID/mri/aparc+aseg.mgz
datadir=derivatives/dMRI/sub-$sID
space=anat

while [ $# -gt 0 ]; do
    case "$1" in
	-segm) shift; segm=$; ;;
  -space) shift; space=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Registration of dMRI and sMRI and transformation into dMRI-space
Subject:       	   $sID 
FS segm:	         $segm
Directory:     	   $datadir 
Space:             $space
$BASH_SOURCE   	   $command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

script=`basename $0 .sh`
echo Executing: $codedir/$script.sh $command > ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo

##################################################################################
# 0. Put files in $datadir

if [ ! -d $datadir/anat ]; then mkdir -p $datadir/anat; fi

if [ ! -f $datadir/anat/fs-segm_aparc+aseg.nii.gz ]; then
    mrconvert $segm $datadir/anat/fs-segm_aparc+aseg.nii.gz
fi

##################################################################################
# 1. Generate 5TT image and extra files (directly in dMRI space)
#


if [ ! -d $datadir/dwi/5tt ]; then mkdir -p $datadir/dwi/5tt; fi
cd $datadir/dwi/5tt

if [ "$space" == "dwi" ]; then
    


    # Generate 5tt and transform into dMRI space directly
    if [ ! -f 5tt_space-dwi.mif.gz ]; then
        mrtransform ../../anat/fs-segm_aparc+aseg.nii.gz -linear ../../xfm/dwi_2_t1w_mrtrix-bbr.mat ../../anat/fs-segm_aparc+aseg_space-dwi.mif.gz -inverse
        5ttgen -force freesurfer -sgm_amyg_hipp ../../anat/fs-segm_aparc+aseg_space-dwi.mif.gz 5tt_space-dwi.mif.gz
    fi

    # Create for visualisation 
    if [ ! -f 5ttvis_space-dwi.mif.gz ]; then
        5tt2vis 5tt_space-dwi.mif.gz 5tt_space-dwi_vis.mif.gz
    fi
    # and GM/WM boundary
    if [ ! -f 5ttgmwm_space-dwi.mif.gz ]; then
        5tt2gmwmi 5tt_space-dwi.mif.gz 5tt_space-dwi_gmwmi.mif.gz
    fi
fi
if [ "$space" == "anat"]; then
    if [ ! -f 5tt_space-anat.mif.gz ]; then
        5ttgen -force freesurfer -sgm_amyg_hipp ../fs-segm_aparc+aseg.nii.gz 5tt_space-anat.mif.gz
    fi

        # Create for visualisation 
    if [ ! -f 5ttvis.mif.gz ]; then
        5tt2vis 5tt_space-anat.mif.gz 5tt_space-anat_vis.mif.gz
    fi
    # and GM/WM boundary
    if [ ! -f 5ttgmwm.mif.gz ]; then
        5tt2gmwmi 5tt_space-anat.mif.gz 5tt_space-anat_gmwmi.mif.gz
    fi
fi

cd $studydir
