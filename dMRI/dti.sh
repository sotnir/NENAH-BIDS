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
    -h|-help)
      usage
      ;;
    *)
      sID=$1
      shift
      ;;
  esac
done

#  check sub id has been given
if [ -z "$sID" ]; then
  echo "Error: No subject ID provided."
  usage
  exit 1
fi



studydir=$PWD
datadir="${studydir}/derivatives/dMRI/sub-$sID"
dwi_mask="${datadir}/dwi/mask_space-dwi_hires.mif.gz"
dt="${datadir}/dwi/dti/dt_hires.mif,gz"


#### Fit tensor to dwi hires data

dti_dir=$(dirname "$dt")

if [ ! -d "$dti_dir" ]; then
    mkdir -p "$dti_dir"
fi

if [ ! -f "$dt" ]; then
    echo "Fitting tensor with mask_space-dwi_hires for $sID..."
    dwi2tensor -iter "0" -mask $dwi_mask $dt
    echo ""

    if [ -f "$dt" ]; then
        echo "dt-file created successfully!"
    else   


mrtransform fa_in - | tcksample tck.tck - - | tck2connectome  