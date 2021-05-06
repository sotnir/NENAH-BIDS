#!/bin/bash
#
## NENAH Study
#
## PREPROCESS DATA, including:
#   1. conversion to BIDS
#   2. validation of BIDS dataset
#
# Currently needs to be run from main study folder 
# Input
# $1 = subject_id (e.g. P4)

# Exit upon any error
set -exo pipefail

## To make codeFolder a global variable 
# This gobblegook comes from stack overflow as a means to find the directory containing the current function: https://stackoverflow.com/a/246128
codeFolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

###   Global variables:   ###

# Study/subject specific #
studyFolder=`pwd`
rawdataFolder=$studyFolder/rawdata;
dcmFolder=$studyFolder/sourcedata;

# Arguments
sID=$1

logFolder=${studyFolder}/derivatives/preprocessing_logs/sub-${sID}

if [ ! -d $rawdataFolder ]; then mkdir -p $rawdataFolder; fi
# We place a .bidsignore here
if [ ! -f $rawdataFolder/.bidsignore ]; then
echo -e "# Exclude following from BIDS-validator\n" > $rawdataFolder/.bidsignore;
fi

# Log folder
if [ ! -d $logFolder ]; then mkdir -p $logFolder; fi

# we'll be running the Docker containers as yourself, not as root:
userID=$(id -u):$(id -g)

###   Get docker images:   ###
docker pull nipy/heudiconv:latest
docker pull bids/validator:latest
#docker pull poldracklab/pydeface:latest
docker pull poldracklab/mriqc:latest

###   Extract DICOMs into BIDS:   ###
# The images were extracted and organized in BIDS format:

docker run --name heudiconv_container \
           --user $userID \
           --rm \
           -it \
           --volume $studyFolder:/base \
           --volume $dcmFolder:/dataIn:ro \
           --volume $rawdataFolder:/dataOut \
           nipy/heudiconv \
               -d /dataIn/sub-{subject}/*/*.dcm \
               -f /base/code/nenah_heuristic.py \
               -s ${sID} \
               -c dcm2niix \
               -b \
               -o /dataOut \
               --overwrite \
           > ${logFolder}/sub-${sID}_dcmSourcedatadcm2niftiRawdata.log 2>&1 
           
# heudiconv makes files read only
#    We need some files to be writable, eg for defacing
chmod -R u+wr,g+wr ${studyFolder}

###   Run BIDS validator   ###
docker run --name BIDSvalidation_container \
           --user $userID \
           --rm \
           --volume $rawdataFolder:/data:ro \
           bids/validator \
               /data \
           > ${studyFolder}/derivatives/bids-validator_report.txt 2>&1
           
###   Deface:   ###
# The anatomical images were defaced using PyDeface:
# FL - Should we do this?

###   MRIQC:   ###
# mriqc_reports folder contains the reports generated by 'mriqc'
docker run --name mriqc_container \
           --user $userID \
           --rm \
           --volume $studyFolder:/data \
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
