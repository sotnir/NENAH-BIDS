#!/bin/bash
# Pre-process of rs-fMRI data for Melodic (assumes Do_fsl_prepare_Melodic.sh has been run)
# Specifically the script crops data (optional), runs motion correction/detection and defines example_func (mid-frame of time-series)
#
# Input
# $1 = path to fmri-folder (e.g. pat/rsfMRI)
# (optional) $2 = dummy scans to crop (default no cropping) (NOTE: In IfLS scanner protocol initial frames already cropped by scanner)
#
# Output
# motion-correction parameters, time-series (spline resampl) and plots in /mc 
# motion-rejection frames (vol2volmotion and vol2volDVARS) in txt-files in /mc 

curr_path=`pwd`
fslpath=$1;
# Go to fslpath
cd $fslpath

# Save a simple log
logbase=`basename $0 .sh`; logdate=`date +%Y%m%d_%R`;
echo -e "On $logdate executing\n$0 $@\n" > ${logbase}_$logdate.log;
cat ${logbase}_$logdate.log
echo -e "-------
print out of $0" >> ${logbase}_$logdate.log 
cat $curr_path/$0 >> ${logbase}_$logdate.log 


# -------------- Start preprocessing ------------------

# --- Change datatype to float
echo Change datatype to float
fslmaths orig_func prefiltered_func_data -odt float
# If dummy scans ($2), then crop now
# NOTE: according to JB and Angela so protocol setup with dummies, so no cropping needed!!
if [ $# -gt 1 ]; then
    if [ $2 -ne 0 ]; then # means we are going to crop
	crop=$2; vols=`fslnvols prefiltered_func_data`;
	vols=`echo "$vols - $crop" | bc` # update to new nbr of vols
	echo "Deleting initial $crop volumes"
	fslroi prefiltered_func_data prefiltered_func_data $crop $vols;
    fi 
fi

# --- Create directories
if [ ! -d mc ]; then mkdir -p mc; fi

# --- Detect volumes with extensive motion
# Motion-discarding conditions from Smyser et al 2015 (A and B)

# A) vol-to-vol motion > 0.25 mm (i.e. relative motion)
thr=0.25 # motion threshold
echo Detecting volumes with extensive vol-2-vol motion - threshold $thr mm
fsl_motion_outliers -i prefiltered_func_data -o mc/vol2volmotion.mat -p mc/vol2volmotion.png -s mc/vol2volmotion.txt --fdrms --thresh=$thr
# if these should be discarded, run Do_fsl_preprocess_1_mcf_and_discard_vols_Melodic.sh
echo "fMRI vols (index from 0) out of $vols to discard. Vol-to-vol motion threshold is $thr mm" > mc/discarded_vols_vol2volmotion.txt;
i=0; # index runs 0 to vols-1
while read line; do
    if [ `echo "$line > $thr" | bc -l` -gt 0 ]; then
	echo $i >> mc/discarded_vols_vol2volmotion.txt;
    fi;
    ((i++))
done < mc/vol2volmotion.txt
echo ">cat mc/discarded_vols_vol2volmotion.txt"
cat mc/discarded_vols_vol2volmotion.txt

# Define example_func
vols=`fslnvols prefiltered_func_data`; #update vols
if [ $# -gt 2 ]; then 
    mvol=$3; # means that we
else
    mvol=` echo "$vols/2" | bc` # Defined this as the middle volume (works for 2n+1- and 2n-volumes)
fi
echo example_func is vol nbr $mvol of $vols
fslroi prefiltered_func_data example_func $mvol 1;

# Do motion-correction (MCFLIRT) and save as _mcf in /mc
if [ -d mc/prefiltered_func_data_mcf.mat ]; then rm mc/prefiltered_func_data_mcf.mat; fi
echo "Motion-correction (MCFLIRT) to example_func and save as _mcf in /mc"
mcflirt -in prefiltered_func_data -out mc/prefiltered_func_data_mcf -mats -plots -reffile example_func -rmsrel -rmsabs -spline_final
imcp prefiltered_func_data.nii.gz prefiltered_func_data_before_mcf.nii.gz

# Generate motion plots
fsl_tsplot -i mc/prefiltered_func_data_mcf.par -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o mc/rot_mcf.png 
fsl_tsplot -i mc/prefiltered_func_data_mcf.par -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o mc/trans_mcf.png 
fsl_tsplot -i mc/prefiltered_func_data_mcf_abs.rms,mc/prefiltered_func_data_mcf_rel.rms -t 'MCFLIRT estimated mean displacement (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o mc/disp_mcf.png 

# B) vol-to-vol root mean squared BOLD signal intensity change (DVARS) was >0.3%
# CANNOT figure out how to implement this!
# use instead default thr which is the 75th percentile + 1.5 times the InterQuartile Range
fsl_motion_outliers -i mc/prefiltered_func_data_mcf -o mc/vol2volDVARS.mat -p mc/vol2volDVARS.png -s mc/vol2volDVARS.txt --dvars --nomoco
# if these should be discarded, run Do_fsl_preprocess_1_mcf_and_discard_vols_Melodic.sh
echo -e "fMRI vols (index from 0) out of $vols to discard.\nVol-to-vol DVARS threshold is 75th percentile + 1.5 times the InterQuartile Range (default)\nexample_func is vol nbr $mvol - check so not in DVARS discard list below" > mc/discarded_vols_vol2volDVARS.txt;
i=0; # index runs 0 to vols-1
while read line; do
    if [ `echo $line | sed 's/ /+/g' | bc` -ge 1 ]; then # true if one entry on line $i is 1
	echo $i >> mc/discarded_vols_vol2volDVARS.txt;
    fi
    ((i++)) ;
done < mc/vol2volDVARS.mat
echo ">cat mc/discarded_vols_vol2volDVARS.txt"
cat mc/discarded_vols_vol2volDVARS.txt

# Go back to curr_path
cd $curr_path
