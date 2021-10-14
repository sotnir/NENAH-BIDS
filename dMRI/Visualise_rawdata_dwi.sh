#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Simple script to visualize diffusion NII-images BIDS folder (rawdata/sub-\$sID/dwi) in order to do QC of rawdata
Arguments:
  sID    Subject ID   (e.g. NENAHC001) 
Options:
  -dwifolder		BIDS dwi folder location (default: $studyfolder/rawdata/sub-\$s/dwi)
  -h / -help / --help	Print usage.
"
  exit;
}

#Defaults

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

studyfolder=$PWD
dwifolder=$studyfolder/rawdata/sub-$sID/dwi

shift
while [ $# -gt 0 ]; do
    case "$1" in
	-dwifolder) shift; dwifolder=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

##############################################
# START

cd $dwifolder

files=`ls *_dwi.nii*`
echo "Subject: $sID"
echo "All files: $files"
for file in $files; do
    echo -e "\nViewing $file"
    filebase=`basename $file .nii.gz`
    for shell in `mrinfo -quiet -fslgrad $filebase.bvec $filebase.bval -shell_bvalues $file`; do
	echo "viewing b-value: $shell"
	dwiextract $file - -fslgrad $filebase.bvec $filebase.bval -shells $shell -quiet | mrview - -mode 2; 
    done
done

cd $studyfolder
