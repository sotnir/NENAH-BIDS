#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Script to estimate response function and CSD estimation of preprocessed dMRI data 

Arguments:
  sID    Subject ID   (e.g. NENAHC001) 
Options:
  -dwi				processed dMRI data (default: derivatives/dMRI/sub-sID/dwi_preproc_inorm.mif.gz)
  -mask				mask for dMRI data (default: derivatives/dMRI/sub-sID/mask.mif.gz)
  -response			response function used (default: dhollander) (NOTE - if msmt_5tt is used then appropriate 5TT needs to be in \$datadir/5tt/5tt_space-dwi.mif.gz)
  -d / -data-dir	<directory> The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -visualise		binary variable (0 or 1) to create visualisations of responses/csd estimates (default: 0 = no visualisation) 
  -transform		Choose to transform to anatomical space: Yes = 1 or No = 0. (default: 0 (No))
  -h / -help / --help	Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

currdir=`pwd`

# Defaults
dwi=derivatives/dMRI/sub-$sID/dwi/dwi_preproc_hires.mif.gz
mask=derivatives/dMRI/sub-$sID/dwi/mask_space-dwi_hires.mif.gz
datadir=derivatives/dMRI/sub-$sID
response=dhollander
visualise=0
transform=0
act5tt=""

# check whether the different tools are set and load parameters
studydir=$currdir;
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift
while [ $# -gt 0 ]; do
    case "$1" in
	-dwi) shift; dwi=$1; ;;
	-mask) shift; mask=$1; ;;
	-response) shift; response=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-visualise) shift; visualise=$1; ;;
	-transform) shift; transform=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else leave blank
if [ ! -f $dwi ]; then dwi=""; fi
if [[ $response = msmt_5tt ]]; then
    act5tt=5tt/5tt_space-dwi.mif.gz;
fi


echo "dMRI preprocessing
Subject:       	$sID 
DWI:      	$dwi
Reponse:	$response
Mask:		$mask
5TT:		$actdir
Directory:     	$datadir 
$BASH_SOURCE   	$command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

echo dMRI preprocessing subject $sID
script=`basename $0 .sh`
echo Executing: $codedir/dMRI/$script.sh $command > ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo

##################################################################################
# 0. Put files in $datadir
dwifullpath=$dwi
maskfullpath=$mask
dwi=`basename $dwi .mif.gz`
mask=`basename $mask .mif.gz`

# Only copy unless they are not there already
if [ ! -f $datadir/$dwi ]; then
    cp $dwifullpath $datadir/.
fi
if [ ! -f $datadir/$mask ]; then
    cp $maskfullpath $datadir/.
fi


##################################################################################
# 1. Perform response function estimation and CSD estimation

cd $datadir/dwi
if [ ! -d csd ]; then mkdir -p csd; fi

# # ---- Tournier ----
# if [[ $response = tournier ]]; then
#     # response fcn
#     if [ ! -f csd/${response}_response.txt ]; then
# 		echo "Estimating response function use $response method"
# 		dwi2response tournier -force -mask  $mask -voxels csd/${response}_sf.mif $dwi csd/${response}_response.txt
# 		echo Check results: response fcn and sf voxels
# 	if [[ $visualise = 1 ]]; then
# 	    shview  csd/${response}_response.txt
# 	    mrview  meanb0_brain.nii.gz -roi.load csd/${response}_sf.mif -roi.opacity 0.5 -mode 2
# 	fi
#     fi
#     # Do CSD estimation
#     if [ ! -f csd/csd-${response}.mif.gz ]; then
# 		echo "Estimating ODFs with CSD"
# 		dwi2fod -force -mask $mask csd $dwi csd/${response}_response.txt csd/csd-${response}.mif.gz
# 		echo Check results of ODFs
# 	if [[ $visualise = 1 ]]; then
# 	    mrview -load meanb0_brain.nii.gz -odf.load_sh csd/csd-${response}.mif.gz -mode 2
# 	fi
#     fi
#     # Normalise responce fcns and ODFs
#     if [[ ! -f csd/csd-${response}_norm.mif.gz ]]; then
# 		mtnormalise -mask $mask csd/csd-${response}.mif.gz csd/csd-${response}_norm.mif.gz 
#     fi
# fi

# ---- dhollander ----
# if [[ $response = dhollander ]]; then
#     # Estimate response functions with dhollander algorithm
#     if [[ ! -f csd/${response}_wm.txt ]]; then
# 		echo "Estimating response function use $response method"
# 		dwi2response dhollander -force -voxels csd/${response}_sf.mif $dwi csd/${response}_wm.txt csd/${response}_gm.txt csd/${response}_csf.txt
# 		echo "Check results for response fcns (wm, gm and csf) and single-fibre voxels (sf)"
# 	if [[ $visualise = 1 ]]; then
# 	    shview  csd/${response}_wm.txt
# 	    shview  csd/${response}_gm.txt
# 	    shview  csd/${response}_csf.txt
# 	    mrview  meanb0_brain.nii.gz -overlay.load csd/${response}_sf.mif -overlay.opacity 0.5 -mode 2
# 	fi
# 	fi
    # Calculate ODFs
if [[ ! -f csd/csd-${response}_wm_dwi_preproc.mif.gz ]]; then
	echo "Calculating CSD using $response"
	dwi2fod msmt_csd -force -mask $mask.mif.gz $dwi.mif.gz ../../sub-NENAHGRP/dwi/response/${response}_wm_dwi_preproc.txt csd/csd-${response}_wm_$dwi.mif.gz ../../sub-NENAHGRP/dwi/response/${response}_gm_dwi_preproc.txt csd/csd-${response}_gm_$dwi.mif.gz ../../sub-NENAHGRP/dwi/response/${response}_csf_dwi_preproc.txt csd/csd-${response}_csf_$dwi.mif.gz
fi
    # Normalise responce fcns and ODFs
if [[ ! -f csd/csd-${response}_wm_norm_dwi_preproc.mif.gz ]]; then
	mtnormalise -mask $mask.mif.gz csd/csd-${response}_wm_$dwi.mif.gz csd/csd-${response}_wm_norm_$dwi.mif.gz csd/csd-${response}_gm_$dwi.mif.gz csd/csd-${response}_gm_norm_$dwi.mif.gz csd/csd-${response}_csf_$dwi.mif.gz csd/csd-${response}_csf_norm_$dwi.mif.gz 
fi

if [[ $visualise = 1 ]]; then
	mrview -load meanb0_$dwi.mif.gz -odf.load_sh csd/csd-${response}_wm_norm_$dwi.mif.gz -mode 2;
fi

# Transform CSD results to anatomical space if required
if [[ "$transform" == "1" ]]; then
	if [[ ! -f csd/csd-${response}_wm_norm_space-anat.mif.gz ]]; then
        mrtransform csd/csd-${response}_wm_norm_$dwi.mif.gz -reorient_fod yes -linear ../xfm/dwi_2_t1w_mrtrix-bbr.mat csd/csd-${response}_wm_norm_space-anat.mif.gz
    fi
    if [[ ! -f csd/csd-${response}_gm_norm_space-anat.mif.gz ]]; then
        mrtransform csd/csd-${response}_gm_norm_$dwi.mif.gz -reorient_fod yes -linear ../xfm/dwi_2_t1w_mrtrix-bbr.mat csd/csd-${response}_gm_norm_space-anat.mif.gz
    fi
    if [[ ! -f csd/csd-${response}_csf_norm_space-anat.mif.gz ]]; then
        mrtransform csd/csd-${response}_csf_norm_$dwi.mif.gz -linear ../xfm/dwi_2_t1w_mrtrix-bbr.mat csd/csd-${response}_csf_norm_space-anat.mif.gz
    fi
fi


# # ---- MSMT ----
# if [[ $response = msmt_5tt ]]; then
#     response=`echo $response | sed 's/\_/-/g'`
#     # Estimate msmt_csd response functions
#     if [[ ! -f csd/${response}_sf.mif ]]; then
# 		echo "Estimating response function use $response method"
# 		dwi2response msmt_5tt -force -voxels csd/${response}_sf.mif $dwi 5tt/$act5tt csd/${response}_wm.txt csd/${response}_gm.txt csd/${response}_csf.txt
# 		echo "Check results for response fcns (wm, gm and csf) and single-fibre voxels (sf)"
# 	if [[ $visualise = 1 ]]; then
# 	    shview  csd/${response}_wm.txt
# 	    shview  csd/${response}_gm.txt
# 	    shview  csd/${response}_csf.txt
# 	    mrview  meanb0_brain.nii.gz -overlay.load csd/${response}_sf.mif -overlay.opacity 0.5 -mode 2
# 	fi
#     fi
#     # Calculate ODFs
#     if [[ ! -f csd/csd-${response}_csf.mif.gz ]]; then
# 		echo "Calculating CSD using ACT and $response"
# 		dwi2fod msmt_csd -force -mask $mask $dwi csd/${response}_wm.txt csd/csd-${response}_wm.mif.gz csd/${response}_gm.txt csd/csd-${response}_gm.mif.gz csd/${response}_csf.txt csd/csd-${response}_csf.mif.gz
# 	if [[ $visualise = 1 ]]; then
# 	    mrview -load meanb0_brain.nii.gz -odf.load_sh csd/csd-${response}_wm.mif.gz -mode 2;
# 	fi
#     fi
#     # Normalise responce fcns and ODFs
#     if [[ ! -f csd/csd-${response}_wm_norm.mif.gz ]]; then
# 		mtnormalise -mask $mask csd/csd-${response}_wm.mif.gz csd/csd-${response}_wm_norm.mif.gz csd/csd-${response}_gm.mif.gz csd/csd-${response}_gm_norm.mif.gz csd/csd-${response}_csf.mif.gz csd/csd-${response}_csf_norm.mif.gz
#     fi
# fi

cd $currdir

##################################################################################
