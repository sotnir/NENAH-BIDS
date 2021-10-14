#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID [options]
Rigid-body linear registration of dMRI (meanb0) to T1 using BBR
Then tranformation of T1 into dMRI space (by updating headers = no resampling)

Arguments:
  sID				Subject ID (e.g. NENAHC012) 
Options:
  -meanb0			Undistorted brain extracted dMRI meanb0 image  (default: derivatives/dMRI/sub-sID/meanb0_brain.nii.gz)
  -T1				T1 N4-biased (e.g. from FreeSurfer) and to registered to (default: derivatives/sMRI_fs-segmentation/sub-sID/mri/nu.mgz)
  -mask				Mask to brain extract T1 (default: derivatives/sMRI_fs-segmentation/sub-sID/mri/brainmask.mgz)
  -wmsegm			WM segmentation to be used with registration with BBR (default: derivatives/sMRI_fs-segmentation/sub-sID/mri/wm.seg.mgz) 
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
meanb0=derivatives/dMRI/sub-$sID/meanb0_brain.nii.gz
t1w=derivatives/sMRI_fs-segmentation/sub-$sID/mri/nu.mgz
mask=derivatives/sMRI_fs-segmentation/sub-$sID/mri/brainmask.mgz
wmseg=derivatives/sMRI_fs-segmentation/sub-$sID/mri/wm.seg.mgz
datadir=derivatives/dMRI/sub-$sID

while [ $# -gt 0 ]; do
    case "$1" in
	-t1w) shift; t1w=$1; ;;
	-meanb0) shift; meanb0=$1; ;;
	-mask) shift; mask=$1; ;;
	-wmseg) shift; wmseg=$; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Registration of dMRI and sMRI and transformation into dMRI-space
Subject:       	   $sID 
meanb0:	       	   $meanb0
T1:		   $t1w
Mask:		   $mask
FS-wmsegm:	   $wmseg
Directory:     	   $datadir 
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
# 0. Copy to files to relevant location in $datadir (incl .json if present at original location)

if [ ! -d $datadir/anat ]; then mkdir -p $datadir/anat; fi

# Put T1 and mask in $datadir and create T1_brain from mask
if [ ! -f $datadir/anat/t1w.nii.gz ]; then
    mrconvert $t1w $datadir/anat/t1w.nii.gz
fi
if [ ! -f $datadir/anat/mask.nii.gz ]; then
    mrconvert $mask $datadir/anat/space-t1w_mask.nii.gz
fi
if [ ! -f $datadir/anat/t1w_brain.nii.gz ]; then
    mrcalc $mask $t1w -mult $datadir/anat/t1w_brain.nii.gz
fi
# meanb0_brain
if [ ! -f $datadir/meanb0_brain.nii.gz ]; then
    mrconvert $meanb0 $datadir/meanb0_brain.nii.gz
fi
# WM segmentation and make sure it is binarized
if [ ! -f $datadir/anat/fs-wmsegm_aseg.nii.gz ]; then
    mrthreshold -abs 0.5 $wmseg $datadir/anat/fs-wmseg_dseg.nii.gz
fi

# Update variables to point at corresponding and relevant filebases in $datadir
t1w=t1w
mask=space-t1w_mask
meanb0=meanb0
wmseg=fs-wmseg_dseg

##################################################################################
## 1. Do registrations and transform into dMRI space
# Adaption from mine and Kerstin Pannek's MRtrix posts: https://community.mrtrix.org/t/registration-of-structural-and-diffusion-weighted-data/203/8?u=finn

cd $datadir

if [ ! -d reg ]; then mkdir reg; fi

# Do brain extractions of meanb0 and T1 before linear registration
if [ ! -f ${meanb0}_brain.nii.gz ];then
    bet $meanb0.nii.gz ${meanb0}_brain.nii.gz -F -R
fi
     
# Registration using BBR
if [ ! -f reg/${meanb0}_2_${t1w}_flirt-bbr.mat ];then 
    echo "Rigid-body linear registration using FSL's FLIRT"
    flirt -in ${meanb0}_brain.nii.gz -ref anat/${t1w}_brain.nii.gz -dof 6 -omat reg/tmp.mat
    flirt -in ${meanb0}_brain.nii.gz -ref anat/${t1w}_brain.nii.gz -dof 6 -cost bbr -wmseg anat/$wmseg.nii.gz -init reg/tmp.mat -omat reg/dwi_2_t1w_flirt-bbr.mat -schedule $FSLDIR/etc/flirtsch/bbr.sch
    rm reg/tmp.mat
fi
# Transform FLIRT registration matrix into MRtrix format
if [ ! -f reg/dwi_2_t1w_mrtrix-bbr.mat ];then
     transformconvert reg/dwi_2_t1w_flirt-bbr.mat ${meanb0}_brain.nii.gz anat/$t1w.nii.gz flirt_import reg/dwi_2_t1w_mrtrix-bbr.mat
fi
     
cd $studydir

####################################################################################################
## Transform T1 into dMRI space by updating image headers (no resampling!)

cd $datadir

# T1
# note $mask must be pointing to mask in dwi-space 
mrtransform anat/$t1w.nii.gz -linear reg/dwi_2_t1w_mrtrix-bbr.mat anat/${t1w}_space-dwi.mif.gz -inverse
mrcalc anat/${t1w}_space-dwi.mif.gz anat/$mask.mif.gz -mult anat/${t1w}_brain_space-dwi.mig.gz

cd $studydir
