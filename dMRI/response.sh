#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID [options]
Estimation of response function

Arguments:
  sID				Subject ID (e.g. NENAHC003) 
Options:
  -dwi				Preprocessed dMRI data serie (format: .mif.gz) (default: derivatives/dMRI/sub-sID/dwi/dwi_preproc.mif.gz)
  -mask				Mask for dMRI data (format: .mif.gz) (default: derivatives/dMRI/sub-sID/dwi/mask.mif.gz)
  -response			Response function (tournier or dhollander) (default: dhollander)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

shift

currdir=$PWD

# Defaults
datadir=derivatives/dMRI/sub-$sID
dwi=$datadir/dwi/dwi_preproc.mif.gz
mask=$datadir/dwi/mask.mif.gz
response=dhollander

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while [ $# -gt 0 ]; do
    case "$1" in
	-dwi) shift; dwi=$1; ;;
	-mask) shift; mask=$1; ;;
	-response) shift; response=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "CSD estimation of dMRI 
Subject:       $sID 
DWI:	       $dwi
Mask:	       $mask
Response:      $response
Directory:     $datadir 
$BASH_SOURCE   $command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

script=`basename $0 .sh`
echo Executing: $codedir/dMRI/$script.sh $command > ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo


##################################################################################
# 0. Copy to files to datadir (incl .json if present at original location)

for file in $dwi $mask; do
    origdir=`dirname $file`
    filebase=`basename $file .mif.gz`
    outdir=$datadir/dwi
    
    if [ ! -d $outdir ]; then mkdir -p $outdir; fi
    
    if [ ! -f $outdir/$filebase.mif.gz ];then
	cp $file $outdir/.
	if [ -f $origdir/$filebase.json ];then
	    cp $origdir/$filebase.json $outdir/.
	fi
    fi

done

# Update variables to point at corresponding filebases in $datadir
dwi=`basename $dwi .mif.gz`
mask=`basename $mask .mif.gz`

##################################################################################
## Make Response Function estimation and then CSD calcuation

cd $datadir/dwi
dwibase=`basename $dwi .mif.gz`

## ---- Tournier ----
if [[ $response = tournier ]]; then

    # response fcn
    responsedir=response #Becomes as sub-folder in $datadir/dwi
    if [ ! -d $responsedir ];then mkdir -p $responsedir;fi    

    if [ ! -f response/${response}_response.txt ]; then
	echo "Estimating response function use $response method"
	dwi2response tournier -force -mask  $mask.mif.gz -voxels $responsedir/${response}_sf_$dwibase.mif.gz $dwi.mif.gz $responsedir/${response}_response_$dwibase.txt
    fi

    echo Check results: response fcn and sf voxels
    echo shview  response/${response}_response.txt
    echo mrview  meanb0_brain.mif.gz -roi.load $responsedir/${response}_sf_$dwibase.mif.gz -roi.opacity 0.5 -mode 2
fi


## ---- dhollander ----
if [[ $response = dhollander ]]; then
    
    responsedir=response #Becomes as sub-folder in $datadir/dwi
    if [ ! -d $responsedir ];then mkdir -p $responsedir; fi

    if [ ! -f response/${response}_response.txt ]; then
	echo "Estimating response function use $response method"
	dwi2response dhollander -force -mask $mask.mif.gz -voxels $responsedir/${response}_sf_$dwibase.mif.gz $dwi.mif.gz $responsedir/${response}_wm_$dwibase.txt $responsedir/${response}_gm_$dwibase.txt $responsedir/${response}_csf_$dwibase.txt
    fi
    
    echo "Check results for response fcns (wm, gm and csf) and single-fibre voxels (sf)"
    echo shview  $responsedir/${response}_wm_$dwibase.txt
    echo shview  $responsedir/${response}_gm_$dwibase.txt
    echo shview  $responsedir/${response}_csf_$dwibase.txt
    echo mrview  meanb0_brain.mif.gz -overlay.load $responsedir/${response}_sf_$dwibase.mif.gz -overlay.opacity 0.5 -mode 2
    
fi

cd $currdir
