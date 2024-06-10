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

# function to extract subject IDs from dMRI qc_file
subjects_dMRI() {
    local dMRI_file="derivatives/dMRI/QC_dMRI_pipeline.tsv"
    local dMRI_subjects=()
    while IFS=$'\t' read -r subject_id pass_value; do
        if [[ "$pass_value" == "1" || "$pass_value" == "0.5" ]]; then
            dMRI_subjects+=("$subject_id")
        fi
    done < "$dMRI_file"
    echo "${dMRI_subjects[@]}"
}

# function to extract subject IDs from sMRI file
subjects_sMRI() {
    local sMRI_file="derivatives/sMRI_fs-segmentation/QC_fs-segmentation.tsv"
    local sMRI_subjects=()
    while IFS=$'\t' read -r subject_id pass_value; do
        if [[ "$pass_value" == "1" || "$pass_value" == "0.5" ]]; then
            sMRI_subjects+=("$subject_id")
        fi
    done < "$sMRI_file"
    echo "${sMRI_subjects[@]}"
}

# get subject IDs from dMRI file
dMRI_subjects=($(subjects_dMRI))
sMRI_subjects=($(subjects_sMRI))

#
subjects=()

# loop through the dMRI subjects
for subject_id in "${dMRI_subjects[@]}"; do
    if [[ " ${sMRI_subjects[@]} " =~ " $subject_id " ]]; then
        subjects+=("$subject_id")
    fi
done

printf "%s\n" "${subjects[@]}"

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
    files=$(find "$studydir/derivatives/dMRI/sub-${sID}/dwi" -name "*/response/${response}_${tissue}_dwi_preproc.txt")
    response_files+=($files)
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


