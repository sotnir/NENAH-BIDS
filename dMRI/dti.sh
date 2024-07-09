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
dwi_hires="${datadir}/dwi/dwi_preproc_hires.mif.gz"
dt_hires="${datadir}/dwi/dti/dt_hires.mif.gz"
fa_hires_dwi="${datadir}/dwi/dti/fa_hires.mif.gz"
fa_hires_anat="${datadir}/anat/fa_hires_space-anat.mif.gz"
#### Fit tensor to dwi hires data

dti_dir=$(dirname "$dt_hires")

if [ ! -d "$dti_dir" ]; then
    mkdir -p "$dti_dir"
fi

if [ ! -f "$dt_hires" ]; then
    echo "Fitting tensor with dwi_preproc_hires and mask_space-dwi_hires for $sID:"
    dwi2tensor -mask $dwi_mask $dwi_hires $dt_hires
    echo ""

    if [ -f "$dt_hires" ]; then
        echo "dt-file created successfully!"
    else
        echo "Could not perform dwi2tensor for $sID, exiting..."
        exit
    fi
else
    echo " dt-file already exists for $sID"
    echo ""
fi


# create fa_hires.mif.gz using tensor2metric


if [ ! -f "$fa_hires_dwi" ]; then
    echo "Creating FA file from dt_hires for $sID:"
    tensor2metric -fa $fa_hires_dwi $dt_hires
    echo ""

    if [ -f "$fa_hires_dwi" ]; then
        echo "FA file created successfully!"
    else
        echo "Could not create FA file for $sID, exiting..."
        exit
    fi
else
    echo "FA file already exists for $sID"
    echo ""
fi
