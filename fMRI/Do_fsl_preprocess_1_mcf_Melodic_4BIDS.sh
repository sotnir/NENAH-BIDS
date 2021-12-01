#!/bin/bash
## NENAH study
# Date created:  10 Jun 2016
# Date modified: 1 Dec 2021
# Contributors: Finn Lennartsson, Yukai Zou
# Inherited from codes that perform pre-processing of rs-fMRI data for Melodic
# Specifically the script runs motion correction/detection, and defines example_func (mid-frame of time-series)
#
# --- Inputs
# $1 = path to subject-folder (e.g. rawdata/sub-NENAHxxx)
# $2 = number of rs-fMRI run (e.g. 1, 2)
# (optional) dummy scans to crop (default no cropping) (NOTE: In IfLS scanner protocol initial frames already cropped by scanner)
#
# --- Outputs
# See dHCP Release Note 2021 as a reference
# motion-correction parameters, time-series (spline resampl) and plots in derivatives/fMRI/sub-{sID}/fsl_motion_outliers 
# motion-rejection frames (vol2volmotion and vol2volDVARS) in txt-files in derivatives/fMRI/sub-{sID}/fsl_motion_outliers

# Default
studydir=`pwd`
sID=$1;
runID=$2;
rawdatadir=$studydir/rawdata/sub-${sID}/func/
datadir=derivatives/fMRI/sub-${sID}
logdir=$studydir/$datadir/logs

# Go to datadir
if [ ! -d $datadir ];then mkdir -p $datadir; fi
cd $datadir
# Create a symbolic link from the rawdatadir as orig_func
#cd rawdata/sub-${sID}/func/
ln -s $rawdatadir/sub-${sID}_task-rest_dir-AP_run-${runID}_bold.nii.gz orig_func_run-${runID}.nii.gz

# Save a simple log
if [ ! -d $logdir ]; then mkdir -p $logdir; fi
logbase=`basename $0 .sh`; logdate=`date +%Y%m%d_%R`;
echo -e "On $logdate executing\n$0 $@\n" > $logdir/${logbase}_$logdate.log;
cat $logdir/${logbase}_$logdate.log
echo -e "-------
print out of $0" >> $logdir/${logbase}_$logdate.log 
# (1 Dec 2021) YZ: What does this line do?
cat $studydir/$0 >> $logdir/${logbase}_$logdate.log 


# -------------- Start preprocessing ------------------

# --- Change datatype to float
echo Change datatype to float
fslmaths orig_func_run-${runID} prefiltered_func_run-${runID}_data -odt float

# --- Create directories
if [ ! -d fsl_motion_outliers ]; then mkdir -p fsl_motion_outliers; fi

# --- Detect volumes with extensive motion
# Motion-discarding conditions from Smyser et al 2015 (A and B)

# A) vol-to-vol motion > 0.25 mm (i.e. relative motion)
thr=0.25 # motion threshold
echo Detecting volumes with extensive vol-2-vol motion - threshold $thr mm
fsl_motion_outliers -i prefiltered_func_run-${runID}_data -o fsl_motion_outliers/vol2volmotion_run-${runID}.mat -p fsl_motion_outliers/vol2volmotion_run-${runID}.png -s fsl_motion_outliers/vol2volmotion_run-${runID}.txt --fdrms --thresh=$thr
# if these should be discarded, run Do_fsl_preprocess_1_mcf_and_discard_vols_Melodic.sh
echo "fMRI vols (index from 0) out of $vols to discard. Vol-to-vol motion threshold is $thr mm" > fsl_motion_outliers/discarded_vols_vol2volmotion_run-${runID}.txt;
i=0; # index runs 0 to vols-1
while read line; do
    if [ `echo "$line > $thr" | bc -l` -gt 0 ]; then
	echo $i >> fsl_motion_outliers/discarded_vols_vol2volmotion_run-${runID}.txt;
    fi;
    ((i++))
done < fsl_motion_outliers/vol2volmotion_run-${runID}.txt
echo ">cat fsl_motion_outliers/discarded_vols_vol2volmotion_run-${runID}.txt"
cat fsl_motion_outliers/discarded_vols_vol2volmotion_run-${runID}.txt

# Define example_func
vols=`fslnvols prefiltered_func_run-${runID}_data`; #update vols
if [ $# -gt 2 ]; then 
    mvol=$3; # means that we
else
    mvol=` echo "$vols/2" | bc` # Defined this as the middle volume (works for 2n+1- and 2n-volumes)
fi
echo example_func is vol nbr $mvol of $vols
fslroi prefiltered_func_run-${runID}_data example_func $mvol 1;

# Do motion-correction (MCFLIRT) and save as _mcf in /fsl_motion_outliers
if [ -d fsl_motion_outliers/prefiltered_func_run-${runID}_data_mcf.mat ]; then rm fsl_motion_outliers/prefiltered_func_run-${runID}_data_mcf.mat; fi
echo "Motion-correction (MCFLIRT) to example_func and save as _mcf in /fsl_motion_outliers"
mcflirt -in prefiltered_func_run-${runID}_data -out fsl_motion_outliers/prefiltered_func_run-${runID}_data_mcf -mats -plots -reffile example_func -rmsrel -rmsabs -spline_final
imcp prefiltered_func_run-${runID}_data.nii.gz prefiltered_func_run-${runID}_data_before_mcf.nii.gz

# Generate motion plots
fsl_tsplot -i fsl_motion_outliers/prefiltered_func_run-${runID}_data_mcf.par -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o fsl_motion_outliers/rot_mcf_run-${runID}.png 
fsl_tsplot -i fsl_motion_outliers/prefiltered_func_run-${runID}_data_mcf.par -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o fsl_motion_outliers/trans_mcf_run-${runID}.png 
fsl_tsplot -i fsl_motion_outliers/prefiltered_func_run-${runID}_data_mcf_abs.rms,fsl_motion_outliers/prefiltered_func_run-${runID}_data_mcf_rel.rms -t 'MCFLIRT estimated mean displacement (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o fsl_motion_outliers/disp_mcf_run-${runID}.png 

# B) vol-to-vol root mean squared BOLD signal intensity change (DVARS) was >0.3%
# CANNOT figure out how to implement this!
# use instead default thr which is the 75th percentile + 1.5 times the InterQuartile Range
fsl_motion_outliers -i fsl_motion_outliers/prefiltered_func_run-${runID}_data_mcf -o fsl_motion_outliers/vol2volDVARS_run-${runID}.mat -p fsl_motion_outliers/vol2volDVARS_run-${runID}.png -s fsl_motion_outliers/vol2volDVARS_run-${runID}.txt --dvars --nomoco
# if these should be discarded, run Do_fsl_preprocess_1_mcf_and_discard_vols_Melodic.sh
echo -e "fMRI vols (index from 0) out of $vols to discard.\nVol-to-vol DVARS threshold is 75th percentile + 1.5 times the InterQuartile Range (default)\nexample_func is vol nbr $mvol - check so not in DVARS discard list below" > fsl_motion_outliers/discarded_vols_vol2volDVARS_run-${runID}.txt;
i=0; # index runs 0 to vols-1
while read line; do
    if [ `echo $line | sed 's/ /+/g' | bc` -ge 1 ]; then # true if one entry on line $i is 1
	echo $i >> fsl_motion_outliers/discarded_vols_vol2volDVARS_run-${runID}.txt;
    fi
    ((i++)) ;
done < fsl_motion_outliers/vol2volDVARS_run-${runID}.mat
echo ">cat fsl_motion_outliers/discarded_vols_vol2volDVARS_run-${runID}.txt"
cat fsl_motion_outliers/discarded_vols_vol2volDVARS_run-${runID}.txt

# Go back to studydir
cd $studydir
