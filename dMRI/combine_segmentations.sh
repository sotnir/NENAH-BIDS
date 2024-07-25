#!/bin/bash


#!/bin/bash


usage() {
  echo "Usage: $0 [-d data-dir] [-m -mrtrix] [-h help] sID"
  echo "Script to "
  echo ""
  echo "Arguments:"
  echo "  sID              Subject ID (e.g. NENAHC001)"
  echo ""
  echo "Options:"
  echo "  -d / -data-dir   <directory>  The base directory used for output of upsampling files (default: derivatives/dMRI/sub-sID)"
  echo "  -m / -mrtrix                  The PATH to MRTrix3 (default: ../software/mrtrix3)"
  echo "  -h / -help                    Print usage"
  exit 1
}


# return usage if no input arguments
if [ $# -eq 0 ]; then
  usage
fi

# command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|-data-dir)
      datadir=$2
      shift 2
      ;;
    -m|-mrtrix)
      MRTRIXHOME=$2
      shift 2
      ;;
    -h|-help)
      usage
      ;;
    -v|-visualize)
      visualisation=1
      shift
      ;;
    *)
      sID=$1
      shift
      ;;
  esac
done


# default params
studydir=$PWD
datadir="${studydir}/derivatives/dMRI"

# LUTS
fs_lut="../software/freesurfer/FreeSurferColorLUT.txt"
fs_convert="${studydir}/code/NENAH-BIDS/labels_names/convert_fs_thalamus_to_wm.txt"
thomas_lut="../software/hipsthomas/Thomas.lut"


# segmentations


aparc_aseg="${studydir}/derivatives/sMRI-fs_segmentation/$sID/aparc+aseg.mgz"
thomas_segm="${datadir}/derivatives/dMRI/$sID/thalamus.mif"


# outputs
coimbined_segm="${outputdir}/new_file_name.mgz" #fyll i här


### Lägg in combination of left/right thomas från thal_con här ist


if [ ! -f $new_segmentation ]; then
  labelconvert $aparc_aseg $fs_lut $fs_convert - | \
  labelconvert - $fs_default $wm_convert - | \
  mrcalc - 0 -gt $thomas_segm - -if $combined_segm


    


