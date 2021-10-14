#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID [options]
Mapping of segmentation into dMRI space
Requires that registration (linear BBR) has been performed between T1 and dMRI space (by updating headers = no resampling)

Arguments:
  sID				Subject ID (e.g. NENAHC012) 
Options:
  -seg				Segmentation to be mapped (default: derivatives/sMRI_fs-segmentation/sub-sID/mri/aparc+aseg.mgz)
  -transform			Transformation matrix (default: derivatives/dMRI/sub-sID/reg/dwi_2_t1w_mrtrix-bbr.mat)
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
seg=derivatives/sMRI_fs-segmentation/sub-$sID/mri/aparc+aseg.mgz
transform=derivatives/dMRI/sub-$sID/reg/dwi_2_t1w_mrtrix-bbr.mat
datadir=derivatives/dMRI/sub-$sID

while [ $# -gt 0 ]; do
    case "$1" in
	-seg) shift; seg=$1; ;;
	-transform) shift; transform=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Registration of dMRI and sMRI and transformation into dMRI-space
Subject:       	   $sID 
FS segm:	   $seg
Tranformation:	   $transform
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
if [ ! -d $datadir/reg ]; then mkdir -p $datadir/reg; fi

# FS segmentation 
if [ ! -f $datadir/anat/fs-segm_aparc+aseg.nii.gz ]; then
    mrconvert $seg $datadir/anat/fs-segm_aparc+aseg.nii.gz
fi

# FS segmentation
transformbase=`basename $transform`
if [ ! -f $datadir/reg/$transformbase ]; then
    cp $transform $datadir/reg/$transformbase
fi

# Update variables to point at corresponding and relevant filebases in $datadir
seg=fs-segm_aparc+aseg
transform=$transformbase

##################################################################################
## Transform FS segmentation into dMRI space by updating image headers (no resampling!)

cd $datadir

# FS segmentation 
mrtransform anat/$seg.nii.gz -linear reg/$transform anat/${seg}_space-dwi.mif.gz -inverse

cd $studydir
