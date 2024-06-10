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
codedir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
datadir=derivatives/dMRI/sub-NENAHGRP/dwi/response
qc_dMRI_file="derivatives/dMRI/QC_dMRI_pipeline.tsv"
qc_sMRI_file="derivatives/sMRI_fs-segmentation/QC_fs-segmentation.tsv"
response=dhollander


# command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
    -d|-data-dir)  shift; basedir=$1; ;;
    -h|-help|--help) usage; ;;
    -response) shift; response=$1; ;;
    -*) echo "$0: Unrecognized option $1" >&2; usage; ;;
    *) break ;;
    esac
    shift
done

get_subjects() {
  local qc_dMRI_file="$1"
  local qc_sMRI_file="$2"
  local -a subjects=()

  # loop through the lines of QC files
  while IFS=$'\t' read -r dMRI_ID dMRI_pass sMRI_ID sMRI_pass; do
    # check if both passes are either 1 or 0.5
    if [[ "$dMRI_pass" =~ ^(1|0\.5)$ ]] && [[ "$sMRI_pass" =~ ^(1|0\.5)$ ]]; then
      # if ok, add the subject ID to the subjects array
      subjects+=("$dMRI_ID")
    fi
  done < <(paste "$qc_dMRI_file" "$qc_sMRI_file")

  echo "${subjects[@]}"
}

# get subject IDs from QC files
subjects=$(get_subjects "$qc_dMRI_file" "$qc_sMRI_file")

echo "This is subjects: $subjects"

# call response.sh for each subject
run_response_calculation() {
  local subjects=("$@")
  for sID in "${subjects[@]}"; do
    "$codedir/response.sh" "$sID" -response $response
  done
}


output_dir=$studydir/$datadir
if [ ! -d $output_dir ]; then mkdir -p $output_dir; fi

# function to calculate group average response 
calculate_group_average() {
  local tissue=$1
  local output_file="${output_dir}/${response}_${tissue}_dwi_preproc.txt"
  local response_files=()

  for sID in "${subjects[@]}"; do
    echo " this is try sID $sID"
    # files=$(find "$studydir/derivatives/dMRI/sub-${sID}/dwi" -name "*/response/${response}_${tissue}_dwi_preproc.txt")
    # response_files+=($files)
  done

  # check if any response function files exist
  if [ ${#response_files[@]} -eq 0 ]; then
    echo "No $tissue response function files found."
    return
  fi

    #using responsemean
  responsemean ${response_files[@]} $output_file
}

# run response calculation for each subject
run_response_calculation "${subjects[@]}"

# calculate group averages for WM, GM, and CSF
calculate_group_average "wm"
calculate_group_average "gm"
calculate_group_average "csf"

if [ -f "${output_dir}/${response}_wm_dwi_preproc.txt" ] && [ -f "${output_dir}/${response}_gm_dwi_preproc.txt" ] && [ -f "${output_dir}/${response}_csf_dwi_preproc.txt" ]; then
  echo "Group average response function calculation completed. Files are saved in $output_dir."
else
  echo "Group average response function calculation unsuccessful."
fi


