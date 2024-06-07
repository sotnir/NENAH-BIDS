#!/bin/bash
# NENAH Study - Group Average Response Function Calculation

usage()
{
  base=$(basename "$0")
  echo "usage: $base [options]
Group average response function calculation for WM, GM, and CSF.
Using subjects with pass value of 1 and 0.5 in QC_dMRI_pipeline.tsv and QC_fs-segmentation.tsv.

Arguments:
  base                          Path to derivites-folder (e.g. derivatives)
Options:
  -response                     Response algorithm (default: dhollander)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-NENAHGRP/dwi/response)
  -h / -help / --help           Print usage.

Output:
  The resulting files for WM, GM, and CSF are saved in /NENAH_BIDS/derivatives/dMRI/sub-NENAHGRP/dwi/response.
"
  exit;
}

################ ARGUMENTS ################

# defaults
studydir=$PWD
basedir=$studydir/NENAH_BIDS/derivatives
qc_dMRI_file="$basedir/dMRI/QC_dMRI_pipeline.tsv"
qc_sMRI_file="$basedir/sMRI_fs_segmentation/QC_fs-segmentation.tsv"
response=dhollander

# command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
    -d|-data-dir)  shift; basedir=$1
                   qc_dMRI_file="$basedir/dMRI/QC_dMRI_pipeline.tsv"
                   qc_sMRI_file="$basedir/sMRI_fs_segmentation/QC_fs-segmentation.tsv"; ;;
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
    ./response.sh "$sID" -response $response
  done
}

output_dir=$basedir/dMRI/sub-NENAHGRP/dwi/response
if [ ! -d $output_dir ]; then mkdir -p $output_dir; fi

# function to calculate group average response 
calculate_group_average() {
  local tissue=$1
  local output_file="${output_dir}/${response}_${tissue}_response.txt"
  local response_files=$(find $basedir/dMRI -name "${tissue}_response.txt")

  # check if any response function files exist
  if [ -z "$response_files" ]; then
    echo "No $tissue response function files found."
    return
  fi

    #using responsemean 
  responsemean $response_files $output_file
}

# run response calculation for each subject
run_response_calculation "${subjects[@]}"

# calculate group averages for WM, GM, and CSF
calculate_group_average "wm"
calculate_group_average "gm"
calculate_group_average "csf"

echo "Group average response function calculation completed. Files are saved in $output_dir."

