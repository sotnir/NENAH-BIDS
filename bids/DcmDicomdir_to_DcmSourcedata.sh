#!/bin/bash
#
## NENAH study
#
## PREPROCESS DATA, including:
#   1. arrangement of DICOMs into organised folders in /sourcedata folder
#
# Is run from BIDS-folder 
# Input
# $1 = subject_id (e.g. P4, NENAH007)

# Exit upon any error
set -exo pipefail

## To make codeFolder a global variable 
# This gobblegook comes from stack overflow as a means to find the directory containing the current function: https://stackoverflow.com/a/246128
codeFolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Study/subject specific #
studyFolder=`pwd`;
origdcmFolder=$studyFolder/dicomdir;
dcmFolder=$studyFolder/sourcedata

# Arguments
sID=$1
logFolder=${studyFolder}/derivatives/preprocessing_logs/sub-${sID}

if [ ! -d $logFolder ]; then mkdir -p $logFolder; fi

# Re-arrange DICOMs into sourcedata
if [ ! -d $dcmFolder ]; then mkdir $dcmFolder; fi
dcm2niix -b o -r y -w 1 -o $dcmFolder -f sub-$sID/s%2s_%d/%d_%5r.dcm $origdcmFolder/${sID}

# Simple log
echo "Executing $0 $@ "> ${logFolder}/sub-${sID}_dcm2sourcedata.log 2>&1 
cat $0 >> ${logFolder}/sub-${sID}_dcm2sourcedata.log 2>&1 
