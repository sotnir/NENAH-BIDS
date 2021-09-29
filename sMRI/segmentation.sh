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
  -T1				T1 image (default: derivatives/sMRI/preproc/sub-sID/sub-sID_desc-process_T1w.nii.gz)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/sMRI/segmentation)
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
t1w=derivatives/sMRI/preproc/sub-${sID}/sub-${sID}_desc-process_T1w.nii.gz
datadir=derivatives/sMRI/segmentation
# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift
while [ $# -gt 0 ]; do
    case "$1" in
	-T1) shift; t1w=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
if [ ! -f $tw1 ]; then tw1=""; fi

echo "Preprocessing for sMRI data using FreeSurfer
Subject:       $sID 
T1:	       $t1w 
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
# Setup FS SUBJECTS DIR
export SUBJECTS_DIR=$PWD/$datadir

##################################################################################
# Run FreeSurfer

recon-all -all -s $sID -i $t1w -threads 10
