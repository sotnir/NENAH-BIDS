#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Simple script to rsync NII-images (no JSON-files) in BIDS rawdata/sub-\$sID/dwi from one source (UoS server) to another destionation 
Arguments:
  sID    Subject ID   (e.g. NENAHC001) 
Options:
  -source		source BIDS location (default: fjl1f15@Soton:/local/scratch/disk2/research/NENAH_BIDS)
  -dest			destination BIDS location (default: $studyfolder/rawdata/sub-\$s)
  -h / -help / --help	Print usage.
"
  exit;
}

#Defaults

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

studyfolder=$PWD
source=fjl1f15@Soton:/local/scratch/disk2/research/NENAH_BIDS/rawdata/sub-$sID/dwi
dest=$studyfolder/rawdata/sub-$sID/dwi

shift
while [ $# -gt 0 ]; do
    case "$1" in
 -source) shift; source=$1; ;;
 -dest) shift; dest=$1; ;;
 -h|-help|--help) usage; ;;
 -*) echo "$0: Unrecognized option $1" >&2; usage; ;;
 *) break ;;
    esac
    shift
done

#############################################
# Start script

if [ ! -d $dest ]; then mkdir -p $dest; fi

echo "Performing rsync of NII-images in $source to $dest"
rsync -avz $source/*_dwi.nii* $source/*_dwi.bval $source/*_dwi.bvec $dest/

