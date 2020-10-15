## NENAH study

## PREPROCESS DATA, including:
#   1. arrangement of DICOMs into organised folders in /sourcedata folder
#
# Currently needs to be run from main data_BIDS-folder 
# Input
# $1 = subject_id (e.g. P4)

# Exit upon any error
set -exo pipefail

## To make CODE_DIR as global variable 
source code/setup.sh

# Study/subject specific #
codeFolder=$CODE_DIR;
studyFolder=`dirname -- "$codeFolder"`;
origdcmFolder=$studyFolder/dicomdir;
dcmFolder=$studyFolder/sourcedata
niftiFolder=$studyFolder/sourcedataNifti

subjectID=$1
#sessionID=$2 #we don't have sessions in NENAH
logFolder=${studyFolder}/derivatives/preprocessing_logs/sub-${subjectID}

if [ ! -d $logFolder ]; then mkdir -p $logFolder; fi

# Re-arrange DICOMs into sourcedata
if [ ! -d $dcmFolder ]; then mkdir $dcmFolder; fi
dcm2niix -b o -r y -o $dcmFolder -w 1 -f sub-$subjectID/s%2s_%d/%d_%5r.dcm $origdcmFolder/${subjectID}

# Also create a sourcedataNifti where all the DICOMs are plainly converted into NIfTIs
# Good to keep for future (however _sbref valid BIDS field in /dwi and /func)
if [ ! -d $niftiFolder ]; then mkdir $niftiFolder; fi
dcm2niix -b y -ba y -z y -w 1 -o $niftiFolder -f sub-$subjectID/s%2s_%d $origdcmFolder/${subjectID}

# Simple log
echo "Executing $0 $@ "> ${logFolder}/sub-${subjectID}_dcm2sourcedata.log 2>&1 
cat $0 >> ${logFolder}/sub-${subjectID}_dcm2sourcedata.log 2>&1 
