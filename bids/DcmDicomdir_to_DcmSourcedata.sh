#!/bin/bash
## NENAH study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
"Arrangement of DICOMs into organised folders in /sourcedata folder

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
studydir=`pwd`
origdcmdir=$studydir/dicomdir;
dcmdir=$studydir/sourcedata
scriptname=`basename $0 .sh`

logdir=${studydir}/derivatives/preprocessing_logs/sub-${sID}
if [ ! -d $logdir ]; then mkdir -p $logdir; fi

################ PROCESSING ################

# Simple log
echo "Executing $0 $@ "> ${logdir/sub-${sID}_dcm2sourcedata.log 2>&1 
cat $0 >> ${logdir}/sub-${sID}_$scriptname.log 2>&1 

# Re-arrange DICOMs into sourcedata
if [ ! -d $dcmFolder ]; then mkdir $dcmFolder; fi
dcm2niix -b o -r y -w 1 -o $dcmFolder -f sub-$sID/s%2s_%d/%d_%5r.dcm $origdcmFolder/${sID} \
	>> {logdir}/sub-${sID}_$scriptname.log 2>&1 

