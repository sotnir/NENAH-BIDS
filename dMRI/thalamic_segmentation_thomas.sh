#!/bin/bash

studydir=$PWD
fs_dir="${studydir}/derivatives/sMRI_fs-segmentation"
thomas_dir="${studydir}/derivatives/sMRI_thalamic_thomas"
max_subjects=20
count=0
start_processing=false


start_subject="NENAH004"
skip_subjects=("NENAHGRP" "NENAHC004" "NENAH052" "NENAH017" "NENAH02" "NENAH008")

for sub_dir in "$fs_dir"/sub-*; do
    sub_id=$(basename "$sub_dir")
    sID="${sub_id#sub-}"

    if [[ "$sID" == "$start_subject" ]]; then
        start_processing=true
    fi

    if $start_processing && [[ ! " ${skip_subjects[@]} " =~ " ${sID} " ]]; then
        if [[ $count -lt $max_subjects ]]; then
            mgz_file="${fs_dir}/${sub_id}/mri/T1w.mgz"
            nii_file="${thomas_dir}/${sub_id}/${sub_id}_T1w.nii.gz"

            if [[ ! -f ${nii_file} ]]; then
                mkdir -p "$(dirname "$nii_file")"

                if [[ -f "$mgz_file" ]]; then
                    mrconvert "$mgz_file" "$nii_file"
                    echo "Converted $mgz_file to $nii_file"
                else
                    echo "Input file $mgz_file does not exist, skipping..."
                    break
                fi
            fi

            if [[ -f "$nii_file" && ! -d "${thomas_dir}/${sub_id}/left" && ! -d "${thomas_dir}/${sub_id}/right" ]]; then
                echo "Performing HIPS-THOMAS segmentation for ${sID}"
                cd "${thomas_dir}/${sub_id}"
                docker run -v ${PWD}:${PWD} -w ${PWD} --user $(id -u):$(id -g) --rm -t anagrammarian/thomasmerged bash -c "hipsthomas_csh -i ${sub_id}_T1w.nii.gz -t1"
            fi

            if [[ -d "${thomas_dir}/${sub_id}/left" && -d "${thomas_dir}/${sub_id}/right" ]]; then
                echo "HIPS-THOMAS segmentation completed for ${sID}"
                echo "Removing directories with temp files in ${sID} directory..."
                rm -rf ${thomas_dir}/${sub_id}/temp
                rm -rf ${thomas_dir}/${sub_id}/tempr
                cd "${studydir}"
            fi
        else
            break
        fi
    else
        echo "### Did not process $sID ###"
    fi
done
