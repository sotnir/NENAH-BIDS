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
# (11 May) Commented out
# userID=$(id -u):neuropediatrics
# becauase trying to with group neuropediatrics (as above) we get error msg
# docker: Error response from daemon: unable to find group neuropediatrics: no matching entries in group file.


###   Get docker images:   ###
docker pull nipy/heudiconv:latest
docker pull bids/validator:latest
#docker pull poldracklab/pydeface:latest
docker pull poldracklab/mriqc:latest
#docker pull nipreps/fmriprep:latest

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
	       --grouping accession_number \
           > $logdir/sub-${sID}_$scriptname.log 2>&1 
           
# heudiconv makes files read only
#    We need some files to be writable, eg for defacing
# (11 May) Commented out
#chmod -R u+wr,g+wr $rawdatadir

## FL: 	Either we terminate here!
## 	and we run corrections scripts/routines like pyhton-scripts for slice_timing seperately followed by BIDS validator
## 	or put routines here and carry on with BIDS validator afterwards



###   Run BIDS validator   ###
docker run --name BIDSvalidation_container \
           --user $userID \
           --rm \
           --volume $rawdatadir:/data:ro \
           bids/validator \
               /data \
	   --ignoreNiftiHeaders \
	   --ignoreWarnings
           > $studydir/derivatives/bids-validator_report.txt 2>&1
           
###   Deface:   ###
# The anatomical images were defaced using PyDeface:
# FL - Should we do this?

###   MRIQC:   ###
# mriqc_reports folder contains the reports generated by 'mriqc'
# partipant level
echo "now run mriqc for ${sID} at participant level, output at /derivatives/mriqc_reports"
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
	       --no-sub \
           > $logdir/sub-${sID}_mriqc_participant.log 2>&1
# FL 2021-05-25 - added MRIQC group level
# group level
echo "now run mriqc for ${sID} at group level, output at /derivatives/mriqc_reports"
docker run --name mriqc_container \
           --user $userID \
           --rm \
           --volume $studydir:/data \
           poldracklab/mriqc \
               /data \
               /data/derivatives/mriqc_reports \
               group \
           > $logdir/sub-${sID}_mriqc_group.log 2>&1

###   fMRIPprep:   ###
# Moved to /fMRI
