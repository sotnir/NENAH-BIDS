#!/bin/bash
## NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Run fMRIprep without FS (for testing)

Arguments:
  sID				Subject ID (e.g. NENAHC001) 
Options:
  -fs_folder 			FreeSurfer folder to input.
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

# Define Folders
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
studydir=$PWD
rawdatadir=$studydir/rawdata;
fsLicense=${FREESURFER_HOME}/license.txt

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

# Defaults
nthreads=10;
fs_folder=$studyfolder/derivatives/sMRI_fs-segmentation

shift
while [ $# -gt 0 ]; do
    case "$1" in
    	-fs_folder) shift; fs_folder=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

scriptname=`basename $0 .sh`
logdir=$studydir/derivatives/preprocessing_logs/sub-${sID}

if [ ! -d $rawdatadir ]; then mkdir -p $rawdatadir; fi
if [ ! -d $logdir ]; then mkdir -p $logdir; fi

# We place a .bidsignore here
if [ ! -f $rawdatadir/.bidsignore ]; then
echo -e "# Exclude following from BIDS-validator\n" > $rawdatadir/.bidsignore;
fi

# we'll be running the Docker containers as yourself, not as root:
userID=$(id -u):$(id -g)

###   Get docker images:   ###
docker pull nipreps/fmriprep:latest

################ PROCESSING ################

###   fMRIprep:   ###
# fmriprep folder contains the reports and results of 'fmriprep'
# FL - how should we run this?
# YZ - code added below for testing
# FL - changed code coher with https://github.com/WinawerLab/SampleData/blob/master/s1_preprocess-data.sh
echo "now run fmriprep for ${sID}, output at /derivatives"
docker run --rm \
    --volume $rawdatadir:/data:ro \
    --volume $studydir/derivatives/fmriprep:/out \
    --volume $fs_folder:/fs \
    --volume $FREESURFER_HOME/license.txt:/opt/freesurfer/license.txt \
    nipreps/fmriprep \
        /data \
        /out \
        participant \
        --participant_label ${sID} \
	--skip_bids_validation \
	--fs-subjects-dir /fs \
	--nthreads $nthreads \
	--fd-spike-threshold 0.35 \
	--stop-on-first-crash \
	-w $HOME
    > $logdir/sub-${sID}_fmriprep_participant.log 2>&1
# FL - Add group level?
