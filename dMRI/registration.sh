#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID [options]
Rigid-body linear registration of dMRI (meanb0) to T1w (NOTE - currently BBR not implemented, should be)
Then tranformation into dMRI space (by updating headers = no resampling) of
- T1 (that has been used for segmentation)
- all_labels parcellation image (in T2-space) created from segmentation
- labels parcellation image (in T2-space) created from segmentation

Arguments:
  sID				Subject ID (e.g. NENAHC012) 
Options:
  -meanb0			Undistorted brain extracted dMRI mean b0 image  (default: derivatives/dMRI_topupeddy/sub-sID/meanb0_brain.nii.gz)
  -T1				T1 that has been segmented (FreeSurfer) and will be registered to, should be N4-corrected brain extracted (default: derivatives/sMRI_segmentation-segmentation/sub-sID/ses-ssID/N4/sub-sID_ses-ssID_desc-preproc_T2w.nii.gz)
  -5TT				5TT image of T2, to use for BBR reg and to be transformed into dMRI space (default: derivatives/sMRI/neonatal-segmentation/sub-sID/ses-ssID/5TT/sub-sID_ses-ssID_desc-preproc_T2w_5TT.nii.gz)
  -all_label			all_label file from segmentation, to be transformed into dMRI space (default: derivatives/sMRI/neonatal-segmentation/sub-sID/ses-ssID/segmentations/sub-sID_ses-ssID_desc-preproc_T2w_all_labels.nii.gz)
  -all_label_LUT		LUT for all_label file (default: codedir/../label_names/ALBERT/all_labels.txt)
  -label			label file from segmentation, to be transformed into dMRI space (default: derivatives/sMRI/neonatal-segmentation/sub-sID/ses-ssID/segmentations/sub-sID_ses-ssID_desc-preproc_T2w_labels.nii.gz)
  -label_LUT			LUT for label file (default: codedir/../label_names/ALBERT/labels.txt)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID/ses-ssID)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
shift; 

currdir=`pwd`

# Defaults
meanb0=derivatives/dMRI/sub-$sID/ses-$ssID/meanb0.nii.gz
T2=derivatives/sMRI/neonatal-segmentation/sub-$sID/ses-$ssID/N4/sub-${sID}_ses-${ssID}_desc-preproc_T2w.nii.gz
allLabel=derivatives/sMRI/neonatal-segmentation/sub-$sID/ses-$ssID/segmentations/sub-${sID}_ses-${ssID}_desc-preproc_T2w_all_labels.nii.gz
allLabelLUT=$codedir/../label_names/ALBERT/all_labels.txt
label=derivatives/sMRI/neonatal-segmentation/sub-$sID/ses-$ssID/segmentations/sub-${sID}_ses-${ssID}_desc-preproc_T2w_labels.nii.gz
labelLUT=$codedir/../label_names/ALBERT/labels.txt
atlas=ALBERT
act5tt=derivatives/sMRI/neonatal-segmentation/sub-$sID/ses-$ssID/5TT/sub-${sID}_ses-${ssID}_desc-preproc_T2w_5TT.nii.gz
datadir=derivatives/dMRI/sub-$sID/ses-$ssID

while [ $# -gt 0 ]; do
    case "$1" in
	-T2) shift; T2=$1; ;;
	-meanb0) shift; meanb0=$1; ;;
	-all_label) shift; allLabel=$1; ;;
	-all_label_LUT) shift; allLabelLUT=$1; ;;
	-label) shift; label=$1; ;;
	-label_LUT) shift; labelLUT=$1; ;;
	-a|-atlas) shift; atlas=$1; ;;
	-5TT) shift; act5tt=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Registration of dMRI and sMRI and transformation into dMRI-space
Subject:       	   $sID 
Session:       	   $ssID
meanb0:	       	   $meanb0
Atlas:	       	   $atlas     
T2:		   $T2
5TT:           	   $act5tt
all_labels file:   $allLabel
all_labels LUT:	   $allLabelLUT
labels file:	   $label
labels LUT:	   $labelLUT
Directory:     	   $datadir 
$BASH_SOURCE   	   $command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

script=`basename $0 .sh`
echo Executing: $codedir/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo

##################################################################################
# 0. Copy to files to relevant location in $datadir (incl .json if present at original location)

# Files to go into different locations in $datadir 
for file in $meanb0 $T2 $act5tt $allLabel $label; do
    origdir=dirname $file
    filebase=`basename $file .nii.gz`
    
    if [[ $file = $meanb0 ]]; then outdir=$datadir;fi
    if [[ $file = $T2 ]]; then outdir=$datadir/registration;fi
    if [[ $file = $act5tt ]]; then outdir=$datadir/act;fi
    if [[ $file = $allLabel ]] || [[ $file = $label ]]; then outdir=$datadir/parcellation/$atlas/segmentations;fi

    if [ ! -d $outdir ];then mkdir -p $outdir;fi
			     
    if [ ! -f $datadir/$filebase.nii.gz ];then
	cp $file $outdir/.
	if [ -f $origdir/$filebase.json ];then
	    cp $origdir/$filebase.json $outdir/.
	fi
    fi
done

# LUT to copy
LUTdir=parcellation/$atlas/label_names
if [ ! -d $datadir/$LUTdir ]; then mkdir -p $datadir/$LUTdir ]; fi
for file in $labelLUT $allLabelLUT; do
    filebase=`basename $file`
    if [ ! -f $datadir/$LUTdir/$filebase ];then
	cp $file $datadir/$LUTdir/.
    fi
done

# Update variables to point at corresponding filebases in $datadir
T2=`basename $T2 .nii.gz`
meanb0=`basename $meanb0 .nii.gz`
act5tt=`basename $act5tt .nii.gz`
allLabel=`basename $allLabel .nii.gz`
label=`basename $label .nii.gz`


##################################################################################
## 1. Do registrations and transform into dMRI space
# Adaption from mine and Kerstin Pannek's MRtrix posts: https://community.mrtrix.org/t/registration-of-structural-and-diffusion-weighted-data/203/8?u=finn

cd $datadir

# Do registrations
cd registration

if [ ! -d reg ]; then mkdir reg; fi

# Do brain extractions of meanb0 and T2 before linear registration
if [ ! -f ${meanb0}_brain.nii.gz ];then
    bet ../$meanb0.nii.gz ${meanb0}_brain.nii.gz -F -R
fi
# NOTE - desc-preproc is brain extracted, make this mock with copying. 
if [ ! -f ${T2}_brain.nii.gz ];then
    cp $T2.nii.gz ${T2}_brain.nii.gz
fi
     
# Registration
if [ ! -f reg/${meanb0}_2_${T2}_flirt-dof6.mat ];then 
    echo "Rigid-body linear registration using FSL's FLIRT"
    flirt -in ${meanb0}_brain.nii.gz -ref ${T2}_brain.nii.gz -dof 6 -omat reg/${meanb0}_2_${T2}_flirt-dof6.mat
fi
# Transform FLIRT registration matrix into MRtrix format
if [ ! -f reg/${meanb0}_2_${T2}_mrtrix-dof6.mat ];then
     transformconvert reg/${meanb0}_2_${T2}_flirt-dof6.mat ${meanb0}_brain.nii.gz $T2.nii.gz flirt_import reg/${meanb0}_2_${T2}_mrtrix-dof6.mat
fi
     

cd $currdir

####################################################################################################
## Transformations of T2, 5TT, allLabels-file into dMRI space by updating image headers (no resampling!)

cd $datadir

# T2
mrtransform registration/$T2.nii.gz -linear registration/reg/${meanb0}_2_${T2}_mrtrix-dof6.mat registration/${T2}_space-dwi.nii.gz -inverse
mrconvert registration/${T2}_space-dwi.nii.gz T2w_coreg.mif.gz

# Take care of 5TT
mrtransform act/$act5tt.nii.gz -linear registration/reg/${meanb0}_2_${T2}_mrtrix-dof6.mat act/${act5tt}_space-dwi.nii.gz -inverse
mrconvert act/${act5tt}_space-dwi.nii.gz act/5TT.mif.gz

# Take care of all_labels
labeldir=parcellation/$atlas/segmentations
mrtransform $labeldir/$allLabel.nii.gz -linear registration/reg/${meanb0}_2_${T2}_mrtrix-dof6.mat $labeldir/${allLabel}_space-dwi.nii.gz -inverse
mrconvert $labeldir/${allLabel}_space-dwi.nii.gz $labeldir/all_labels.mif.gz

# Take care of labels
labeldir=parcellation/$atlas/segmentations
mrtransform $labeldir/$label.nii.gz -linear registration/reg/${meanb0}_2_${T2}_mrtrix-dof6.mat $labeldir/${label}_space-dwi.nii.gz -inverse
mrconvert $labeldir/${label}_space-dwi.nii.gz $labeldir/labels.mif.gz

# Create some visualisationclean-up
#rm *tmp* reg/*tmp*

cd $currdir
