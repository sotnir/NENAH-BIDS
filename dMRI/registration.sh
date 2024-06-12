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
  -meanb0			Undistorted brain extracted dMRI meanb0 image  (default: derivatives/dMRI/sub-sID/dwi/meanb0_brain.mif.gz)
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
meanb0=derivatives/dMRI/sub-$sID/dwi/meanb1000_brain_dwi_preproc_hires.mif.gz  
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
if [ ! -f $datadir/anat/space-t1w_mask.nii.gz ]; then
    mrconvert $mask $datadir/anat/space-t1w_mask.nii.gz
fi
if [ ! -f $datadir/anat/t1w_brain.nii.gz ]; then
    mrcalc $mask $t1w -mult $datadir/anat/t1w_brain.nii.gz
fi
# meanb0_brain
# FL - NOTE in NIfTI format .nii.gz
if [ ! -f $datadir/dwi/meanb0_brain.nii.gz ]; then
    mrconvert $meanb0 $datadir/dwi/meanb0_brain.nii.gz
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

if [ ! -d xfm ]; then mkdir xfm; fi

# Do brain extractions of meanb0 and T1 before linear registration
# FL - This is not needed as $meanb0 should be provided brain extracted and saved as $datadir/dwi/meanb0_brain.nii.gz
#if [ ! -f dwi/${meanb0}_brain.nii.gz ];then
#    bet dwi/$meanb0.nii.gz dwi/${meanb0}_brain.nii.gz -F -R
#fi


#creating temp meanb0.nii.gz file with brain extracted meanb1000
mrcalc dwi/meanb0_dwi_preproc_hires.mif.gz dwi/mask_space-dwi_hires.mif.gz -mul dwi/meanb0_brain_hires_tmp.nii.gz 
    
# Registration using BBR
if [ ! -f xfm/${meanb0}_2_${t1w}_flirt-bbr.mat ];then 
    echo "Rigid-body linear registration using FSL's FLIRT"
    flirt -in dwi/${meanb0}_brain_hires_tmp.nii.gz -ref anat/${t1w}_brain.nii.gz -dof 6 -omat xfm/tmp.mat
    flirt -in dwi/${meanb0}_brain_hires_tmp.nii.gz -ref anat/${t1w}_brain.nii.gz -dof 6 -cost bbr -wmseg anat/$wmseg.nii.gz -init xfm/tmp.mat -omat xfm/dwi_2_t1w_flirt-bbr.mat -schedule $FSLDIR/etc/flirtsch/bbr.sch
    rm xfm/tmp.mat
fi
# Transform FLIRT registration matrix into MRtrix format
if [ ! -f xfm/dwi_2_t1w_mrtrix-bbr.mat ];then
    transformconvert xfm/dwi_2_t1w_flirt-bbr.mat dwi/${meanb0}_brain_hires_tmp.nii.gz anat/$t1w.nii.gz flirt_import xfm/dwi_2_t1w_mrtrix-bbr.mat
fi
     
cd $studydir

####################################################################################################
## Transform T1 into dMRI space by updating image headers (no resampling!)

cd $datadir

# T1
mrtransform anat/$t1w.nii.gz -linear xfm/dwi_2_t1w_mrtrix-bbr.mat anat/space-dwi_t1w.mif.gz -inverse
mrtransform anat/$mask.nii.gz -linear xfm/dwi_2_t1w_mrtrix-bbr.mat anat/space-dwi_mask.mif.gz -inverse

# FL - NOTE $mask must be pointing to mask in dwi-space 
mrcalc anat/space-dwi_t1w.mif.gz anat/space-dwi_mask.mif.gz -mult anat/space-dwi_t1w_brain.mif.gz

cd $studydir
