#!/bin/bash
## NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Conversion of DCMs in /sourcedata into NIfTIs in /rawdata
1. NIfTI-conversion to BIDS-compliant /rawdata folder
2. validation of BIDS dataset
3. Run of MRIQC on structural and functional data
4. Run fMRIprep

Arguments:
  sID				Subject ID (e.g. NENAHC001) 
Options:
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

shift
while [ $# -gt 0 ]; do
    case "$1" in
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Define Folders
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
studydir=`pwd` #studydir=`dirname -- "$codedir"`
rawdatadir=$studydir/rawdata;
sourcedatadir=$studydir/sourcedata;
fsLicense=${FREESURFER_HOME}/license.txt
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

###   fMRIPprep:   ###
# fmriprep folder contains the reports and results of 'fmriprep'
# FL - how should we run this?
# YZ - code added below for testing
# FL - changed code coher with https://github.com/WinawerLab/SampleData/blob/master/s1_preprocess-data.sh
echo "now run fmriprep for ${sID}, output at /derivatives"
docker run --rm \
    --volume $rawdatadir:/data:ro \
    --volume $studydir/derivatives:/out \
    --volume $FREESURFER_HOME/license.txt:/opt/freesurfer/license.txt \
    nipreps/fmriprep \
	--skip_bids_validation \
        /data \
        /out \
        participant \
        --participant_label ${sID} \
    > $logdir/sub-${sID}_fmriprep_participant.log 2>&1
# FL - Add group level?
