#!/bin/bash
# NENAH study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Perform segmentation on sMRI data using FreeSurfer
Arguments:
  sID				Subject ID (e.g. NENAH001)
Options:
  -T1				T1 image (default: rawdata/sub-sID/anat/sub-sID_run-1_T1w.nii.gz)
  -hippocampal-subfields-T1	Automated segmentation of the hippocampal subfields (requires the Matlab R2012 runtime)
  -threads			Nbr of CPU cores/threads for FreeSurfer analysis. (default: threads=10)  
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/sMRI_fs-segmentation)
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
t1w=rawdata/sub-${sID}/anat/sub-${sID}_run-1_T1w.nii.gz
datadir=derivatives/sMRI_fs-segmentation
threads=10
# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift
while [ $# -gt 0 ]; do
    case "$1" in
	-T1) shift; t1w=$1; ;;
	-threads) shift; threads=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
if [ ! -f $t1w ]; then t1w=""; fi

# System specific #
# (These are the same for all studies/subjects):
# FreeSurfer license path:
#      We first check whether FREESURFER_LICENSE is an environmnetal variable
#      If not, we assume the path based on Mac OS organization
if [ -z "$FREESURFER_LICENSE" ]
then fsLicense=${FREESURFER_HOME}/license.txt
else fsLicense="$FREESURFER_LICENSE"
fi
[ -r "$fsLicense" ] || {
    echo "FreeSurfer license (${fsLicense}) not found!"
    echo "You can set a custom license path by storing it in the environment variable FREESURFER_LICENSE"
    exit 1
}

echo "Preprocessing for sMRI data using FreeSurfer
Subject:       $sID 
T1:	           $t1w 
threads:       $threads 
Directory:     $datadir 
$BASH_SOURCE   $command
----------------------------"

logdir=derivatives/preprocessing_logs/sub-$sID
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

echo sMRI preprocessing on subject $sID
script=`basename $0 .sh`
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_sMRI_$script.log 2>&1
echo

##################################################################################
# Run FreeSurfer
recon-all -subjid sub-$sID -i $t1w -sd $datadir -threads $threads -all

# Run segmentation of hippocampus and nuclei of amygdala
# See https://surfer.nmr.mgh.harvard.edu/fswiki/HippocampalSubfields
# The module is now in separate scripts:
#   segmentHA_T1.sh
#segmentHA_T1.sh sub-$sID $datadir
