#!/bin/bash

usage() {
  echo "Usage: $0 subjectID [options]
Transforms CSD and 5TT files from diffusion space to anatomical space.

Arguments:
  sID               Subject ID (e.g. NENAHC012)

Options:
  -csd              CSD file in diffusion space (default: derivatives/dMRI/sub-sID/dwi/csd/csd-dhollander_wm_norm.mif.gz)
  -5tt              5TT file in diffusion space (default: derivatives/dMRI/sub-sID/dwi/5tt/5tt_space-dwi.mif.gz)
  -transform        Transformation matrix from diffusion to anatomical space (default: derivatives/dMRI/sub-sID/xfm/dwi_2_t1w_mrtrix-bbr.mat)
  -d / -data-dir    <directory>   Directory used to output the transformed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help  Print usage.
"
  exit;
}

# Check arguments
[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

# Defaults
datadir=derivatives/dMRI/sub-$sID
csd=derivatives/dMRI/sub-$sID/dwi/csd/csd-dhollander_wm_norm.mif.gz
act5tt=derivatives/dMRI/sub-$sID/dwi/5tt/5tt_space-dwi.mif.gz
transform=derivatives/dMRI/sub-$sID/xfm/dwi_2_t1w_mrtrix-bbr.mat

# Parse options
shift
while [ $# -gt 0 ]; do
  case "$1" in
    -csd) shift; csd=$1; ;;
    -5tt) shift; act5tt=$1; ;;
    -transform) shift; transform=$1; ;;
    -d|-data-dir) shift; datadir=$1; ;;
    -h|-help|--help) usage; ;;
    -*) echo "$0: Unrecognized option $1" >&2; usage; ;;
    *) break ;;
  esac
  shift
done

echo "Transforming CSD and 5TT files to anatomical space
Subject:       $sID 
CSD:           $csd
5TT:           $act5tt
Transform:     $transform
Directory:     $datadir 
$BASH_SOURCE   $command
----------------------------"

# Create output directories if they don't exist
outdir_csd=$datadir/anat/csd
outdir_5tt=$datadir/anat/5tt
mkdir -p $outdir_csd
mkdir -p $outdir_5tt

# Transform CSD file
csd_basename=$(basename $csd .mif.gz)
csd_out=$outdir_csd/${csd_basename}_space-anat.mif.gz
if [ ! -f $csd_out ]; then
  echo "Transforming CSD file to anatomical space..."
  mrtransform $csd $csd_out -linear $transform -reorient_fod yes
fi

# Unsure if this step should be run at all, since we still have the input file from fs-segmentation (and might not need 5TT in anat-space)
# (derivatives/dMRI/sub-NENAH002/anat/fs-segm_aparc+aseg.nii.gz)

# # Transform 5TT file
# act5tt_basename=$(basename $act5tt .mif.gz)
# act5tt_out=$outdir_5tt/${act5tt_basename}_anat.mif.gz
# if [ ! -f $act5tt_out ]; then
#   echo "Transforming 5TT file to anatomical space..."
#   mrtransform $act5tt $act5tt_out -linear $transform
# fi

echo "Transformation complete. Transformed files are located in the respective directories."
