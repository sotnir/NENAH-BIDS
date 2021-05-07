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
docker pull nipy/heudiconv:latest
docker pull bids/validator:latest
#docker pull poldracklab/pydeface:latest
docker pull poldracklab/mriqc:latest

################ PROCESSING ################

###   Extract DICOMs into BIDS:   ###
# The images were extracted and organized in BIDS format:

docker run --name heudiconv_container \
           --user $userID \
           --rm \
           -it \
           --volume $studydir:/base \
	   --volume $codedir:/code \
           --volume $sourcedatadir:/dataIn:ro \
           --volume $rawdatadir:/dataOut \
           nipy/heudiconv \
               -d /dataIn/sub-{subject}/*/*.dcm \
               -f /code/nenah_heuristic.py \
               -s ${sID} \
               -c dcm2niix \
               -b \
               -o /dataOut \
               --overwrite \
           > ${logdir}/sub-${sID}_dcmSourcedatadcm2niftiRawdata.log 2>&1 
           
# heudiconv makes files read only
#    We need some files to be writable, eg for defacing
chmod -R u+wr,g+wr $rawdatadir

###   Run BIDS validator   ###
docker run --name BIDSvalidation_container \
           --user $userID \
           --rm \
           --volume $rawdatadir:/data:ro \
           bids/validator \
               /data \
           > $studydir/derivatives/bids-validator_report.txt 2>&1
           
###   Deface:   ###
# The anatomical images were defaced using PyDeface:
# FL - Should we do this?

###   MRIQC:   ###
# mriqc_reports folder contains the reports generated by 'mriqc'
docker run --name mriqc_container \
           --user $userID \
           --rm \
           --volume $studydir:/data \
           poldracklab/mriqc \
               /data \
               /data/derivatives/mriqc_reports \
               participant \
               --ica \
               --verbose-reports \
               --fft-spikes-detector \
               --participant_label ${sID} \
           > ${logFolder}/sub-${sID}_mriqc_participant.log 2>&1

###   fMRIPprep:   ###
# fmriprep folder contains the reports and results of 'fmriprep'
# FL - how should we run this?
