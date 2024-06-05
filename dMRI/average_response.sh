#!/bin/bash
# NENAH Study - Global Average Response Function Calculation

usage()
{
  base=$(basename "$0")
  echo "usage: $base [options]
Global average response function calculation for WM, GM, and CSF.
Using subjects with pass value of 1 and 0.5 in QC_dMRI_pipeline.tsv and QC_fs-segmentation.tsv.

Options:
  -d / -data-dir  <directory>   The directory containing the QC files (default: /NENAH_BIDS/derivatives)
  -h / -help / --help           Print usage.

Output:
  The resulting files for WM, GM, and CSF are saved in /NENAH_BIDS/derivatives/dMRI/sub-NENAHGRP.
"
  exit;
}

################ ARGUMENTS ################

# defaults
datadir=/NENAH_BIDS/derivatives
qc_dMRI_file="$datadir/dMRI/QC_dMRI_pipeline.tsv"
qc_sMRI_file="$datadir/sMRI_fs_segmentation/QC_fs-segmentation.tsv"

# command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
    -d|-data-dir)  shift; datadir=$1
                   qc_dMRI_file="$datadir/dMRI/QC_dMRI_pipeline.tsv"
                   qc_sMRI_file="$datadir/sMRI_fs_segmentation/QC_fs-segmentation.tsv"; ;;
    -h|-help|--help) usage; ;;
    -*) echo "$0: Unrecognized option $1" >&2; usage; ;;
    *) break ;;
    esac
    shift
done

# parse QC files and extract subject IDs with a pass value of 1 or 0.5
get_subjects() {
  local qc_files=("$@")
  local subjects=()
  for file in "${qc_files[@]}"; do
    while IFS=$'\t' read -r Subject_ID qc_preprocess_pass_1_fail_0; do
      if [[ "$Subject_ID" != "Subject_ID" && ("$qc_preprocess_pass_1_fail_0" == "1" || "$qc_preprocess_pass_1_fail_0" == "0.5") ]]; then
        subjects+=("$Subject_ID")
      fi
    done < "$file"
  done
  echo "${subjects[@]}"
}

# get subject IDs from QC files
subjects=$(get_subjects "$qc_dMRI_file" "$qc_sMRI_file")

# call response.sh for each subject
run_response_calculation() {
  local subjects=("$@")
  for sID in "${subjects[@]}"; do
    ./response.sh "$sID" -response dhollander
  done
}

# function to calculate global average response 
calculate_global_average() {
  local tissue=$1
  local output_file=$2
  local response_files=$(find $datadir/dMRI -name "${tissue}_response.txt")

  # check if any response function files exist
  if [ -z "$response_files" ]; then
    echo "No $tissue response function files found."
    return
  fi

  # use responsemean to calculate global average
  responsemean $response_files $output_file
}

# run response calculation for each subject
run_response_calculation "${subjects[@]}"

# calculate global averages for WM, GM, and CSF
output_dir=$datadir/dMRI/sub-NENAHGRP

calculate_global_average "wm" $output_dir/global_wm_response.txt
calculate_global_average "gm" $output_dir/global_gm_response.txt
calculate_global_average "csf" $output_dir/global_csf_response.txt

echo "Global average response function calculation completed. Files are saved in $output_dir."

