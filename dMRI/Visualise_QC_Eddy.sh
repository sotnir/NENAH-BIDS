#!/bin/bash
# NENAH
# Script for QC eye-balling of output generated from preprocess_QC.sh
#

################ SUB-FUNCTIONS ################

usage()
{
  base=$(basename "$0")
  echo "usage: $base sID ssID studydir derivatives [options]
Visualize selected output from preprocess_QC.sh for QC evaluation

Arguments:
    sID                   Subject ID (e.g. NENAH002) 
Options:
  -d / -data-dir	<directory> The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help   Print usage.
"
  exit;
}

dMRI_visualisation ()
{
    # get input file
    file=$1;
	shell_bvalues=`mrinfo -shell_bvalues $file`;
	shell_nbs=`mrinfo -shell_sizes $file`;
	echo b-values $shell_bvalues with dMRI-volumes $shell_nbs
	for shell in $shell_bvalues; do
	    echo Inspecting shell with b-value=$shell
	    dwiextract -quiet -shell $shell $file - | mrview - -mode 2 -colourmap 1
	done
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1
shift; 

studydir=$PWD
datadir=derivatives/dMRI/sub-$sID

codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
scriptname=`basename $0 .sh`

# Read arguments
while [ $# -gt 0 ]; do
    case "$1" in
	-d|-datadir) datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Visual QC of preprocess
----------------------------
Subject:       	$sID
Studydir:       $studydir 
DataDirectory:	$datadir

Codedir:	$codedir
$BASH_SOURCE   	$command
----------------------------"
echo 

################ START ################

#######################################
# Preprocess
echo "############## QC of Process: Preprocess
"
preprocdir = $datadir/dwi/preproc
cd $preprocdir

# Brain Mask
dwi=dwi_den_unr_eddy.mif.gz 
echo "QC of BET Brain Mask"
echo Check the so that brain mask is covering the whole brain but not excessively extends into the extra-axial tissue
echo Visualisation of Brain Mask as an ROI-overlay on meanb1000
dwiextract -quiet $dwi - -shells 1000 | mrmath -quiet - mean - -axis 3 | mrview - -roi.load mask.mif.gz -roi.opacity 0.5 -mode 2
echo

# Final output 
dwi=dwi_den_unr_eddy_unbiased.mif.gz
echo "QC of final preprocessing output (PCA-denoise, Gibbs unring, EDDY, N4-biasfield corrected)"
echo "Check corrected dMRI, shell by shell, for residual motion, signal dropout, (excessive) image distortions"
dMRI_visualisation $dwi;

echo Inspecting SNR/CNR-maps
file=$preprocdir/eddy/eddy_cnr_maps.nii.gz
mrview $file -mode 2

for bvalue in b0 b1000 b2600; do
	echo "Visualization of skull-stripped mean$bvalue"
	mrview mean${bvalue}_brain.mif.gz -mode 2
done
echo

cd $studydir

#######################################

