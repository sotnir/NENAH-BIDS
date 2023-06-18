#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Script to preprocess dMRI data
Preprocessing is gathered in $datadir/preproc 
Uses inputs from QC-file
1. MP-PCA Denoising and Gibbs Unringing 
2. TOPUP and EDDY for motion- and susceptebility image distortion correction
3. N4 biasfield correction
4. Normalisation
5. Creation of a mean B0 image (as average from normalised unwarped b0s)
6. Calculation of tensor and tensor maps (FA, MD etc)

Arguments:
  sID    Subject ID   (e.g. NENAHC001) 
Options:
  -QC			QC file with entries for dir-AP, dir-PA and with good quality b0s for TOPUP (see below how entries should be organized in QC-file) (default: \$codedir/../QC/QC_dwi.csv)
  -d / -data-dir	<directory> The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help	Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

currdir=$PWD
# check whether the different tools are set and load parameters
studydir=$currdir;
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Defaults
QC=$codedir/../QC/QC_dwi.csv
datadir=derivatives/dMRI/sub-$sID
threads=10

shift
while [ $# -gt 0 ]; do
    case "$1" in
 -QC) shift; QC=$1; ;;
 -d|-data-dir)  shift; datadir=$1; ;;
 -h|-help|--help) usage; ;;
 -*) echo "$0: Unrecognized option $1" >&2; usage; ;;
 *) break ;;
    esac
    shift
done

# Assign dwi data from input
# Since it is saved as .csv-file with ',' as delimiter, we change ',' to ' '
sIDrow=`cat $QC | grep $sID | sed 's/\,/\ /g'`
# Column-wise entries in QC file should be:  Subject_ID QC_rawdata_dwi_PASS_1_FAIL_0	rawdata_dir-AP_dwi	rawdata_dir-AP_b0_volume	rawdata_dir-PA_dwi	rawdata_dir-PA_b0_volume    optimal_BET_f-value QC_preprocess

echo $sIDrow

if [[ `echo $sIDrow | awk '{ print $2 }'` == 1 || `echo $sIDrow | awk '{ print $2 }'` == 0.5 ]]; then
    dwiAPfile=`echo $sIDrow | awk '{ print $3 }'`
    dwiAP=rawdata/sub-$sID/dwi/$dwiAPfile
    b0APvol=`echo $sIDrow | awk '{ print $4 }'`
    dwiPAfile=`echo $sIDrow | awk '{ print $5 }'`
    dwiPA=rawdata/sub-$sID/dwi/$dwiPAfile
    b0PAvol=`echo $sIDrow | awk '{ print $6 }'`
else
    echo "Subject $sID has no entry in QC-file, or has no in dwi data that has passed QC"
    exit;
fi

echo "dMRI preprocessing
Subject:       	$sID 
QC file:	$QC
DWI (AP):      	$dwiAP
b0vol (AP):	$b0APvol
DWI (PA):      	$dwiPA
b0vol (PA):	$b0PAvol
Threads:	$threads
$BASH_SOURCE   	$command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

echo dMRI preprocessing subject $sID
script=`basename $0 .sh`
echo Executing: $codedir/dMRI/$script.sh $command > ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo

##################################################################################
# 0. Create subfolder structure in $datadir

if [ ! -d $datadir ]; then mkdir -p $datadir; fi

cd $datadir
if [ ! -d anat ]; then mkdir -p anat; fi
if [ ! -d dwi ]; then mkdir -p dwi; fi
if [ ! -d fmap ]; then mkdir -p fmap; fi
if [ ! -d xfm ]; then mkdir -p xfm; fi
if [ ! -d qc ]; then mkdir -p qc; fi
cd $studydir

##################################################################################

##################################################################################
# 0a. Create dMRI mif-files in $datadir/orig (importing .json and bvecs/bvals files) of original data

if [ ! -d $datadir/dwi/orig ]; then mkdir -p $datadir/dwi/orig; fi

filelist="$dwiAP $dwiPA"
for file in $filelist; do
    filebase=`basename $file .nii.gz`;
    filedir=`dirname $file`
    if [ ! -f $datadir/dwi/orig/$filebase.mif.gz ]; then
	mrconvert -force -json_import $filedir/$filebase.json -fslgrad $filedir/$filebase.bvec $filedir/$filebase.bval $filedir/$filebase.nii.gz $datadir/dwi/orig/$filebase.mif.gz
    fi
done

#Then update variables to only refer to filebase names (instead of path/file)
dwiAP=`basename $dwiAP .nii.gz` 
dwiPA=`basename $dwiPA .nii.gz`


##################################################################################
# 0b. Create dwi.mif.gz as concatenation of dwiAP and dwiPA. This is the file to work with
cd $datadir/dwi

if [[ $dwiAP = "" ]] || [[ $dwiPA = "" ]]; then
    echo "No dwi data provided";
    exit;
else
    # Create a dwi.mif.gz-file to work with
    if [ ! -f dwi.mif.gz ]; then
	mrcat orig/$dwiAP.mif.gz orig/$dwiPA.mif.gz dwi.mif.gz
    fi
fi

cd $currdir

##################################################################################
# 1. Do PCA-denoising and Remove Gibbs Ringing Artifacts

if [ ! -d $datadir/dwi/preproc ]; then mkdir -p $datadir/dwi/preproc; fi

cd $datadir/dwi/preproc

# Point to dwi rawdata, located in $datadir
dwiraw=../dwi.mif.gz


# Directory for MP PCA QC files
if [ ! -d denoise ]; then mkdir denoise; fi

# Perform PCA-denosing
if [ ! -f dwi_den.mif.gz ]; then
    echo Doing MP PCA-denosing with dwidenoise
    # PCA-denoising
    dwidenoise -nthreads $threads $dwiraw dwi_den.mif.gz -noise denoise/dwi_noise.mif.gz;
    # and calculate residuals
    mrcalc $dwiraw dwi_den.mif.gz -subtract denoise/dwi_den_residuals.mif.gz
    echo Check the residuals! Should not contain anatomical structure
fi

# Directory for Gibbs QC files
if [ ! -d unring ]; then mkdir unring; fi

# Perform Gibbs-unringing
if [ ! -f dwi_den_unr.mif.gz ]; then
    echo Remove Gibbs Ringing Artifacts with mrdegibbs
    # Gibbs 
    mrdegibbs -nthreads $threads -axes 0,1 dwi_den.mif.gz dwi_den_unr.mif.gz
    #calculate residuals
    mrcalc dwi_den.mif.gz  dwi_den_unr.mif.gz -subtract unring/dwi_den_unr_residuals.mif.gz
    echo Check the residuals! Should not contain anatomical structure
fi

cd $currdir

##################################################################################
# 2. TOPUP and EDDY for Motion- and susceptibility distortion correction
cd $datadir/dwi/preproc

# Create b0APPA.mif.gz in to go into TOPUP
if [ ! -f b0APPA.mif.gz ];then
    echo Creating a PErevPE pair of SE images to use with TOPUP
    dwiextract -force -bzero ../orig/$dwiAP.mif.gz - | mrconvert -coord 3 $b0APvol -axes 0,1,2 - b0AP.mif.gz
    dwiextract -force -bzero ../orig/$dwiPA.mif.gz - | mrconvert -coord 3 $b0PAvol -axes 0,1,2 - b0PA.mif.gz 
    mrcat -force b0AP.mif.gz b0PA.mif.gz b0APPA.mif.gz
    rm b0AP.mif.gz b0PA.mif.gz
fi

# Do Topup and Eddy with dwipreproc and b0APPA.mif.gz as input
if [ ! -f dwi_den_unr_eddy.mif.gz ]; then
	dwifslpreproc -rpe_header -se_epi b0APPA.mif.gz -eddy_slspec $studydir/sequences/slspec_NENAH_64_interleaved_slices.txt -align_seepi \
	-topup_options " --iout=field_mag_unwarped" \
	-eddy_options " --slm=linear --repol --mporder=16 --s2v_niter=10 --s2v_interp=trilinear --s2v_lambda=1 " \
	-eddyqc_all eddy \
	dwi_den_unr.mif.gz \
	dwi_den_unr_eddy.mif.gz;
   # or use -rpe_pair combo: dwifslpreproc DWI_in.mif DWI_out.mif -rpe_pair -se_epi b0_pair.mif -pe_dir ap -readout_time 0.72 -align_seepi
fi

cd $currdir

##################################################################################
# 3. Mask generation, N4 biasfield correction, meanb0 generation and tensor estimation
cd $datadir/dwi/preproc

echo "Pre-processing with mask generation, N4 biasfield correction"

# point to right filebase
dwi=dwi_den_unr_eddy

# Do B1-correction. Use ANTs N4
if [ ! -f  ${dwi}_unbiased.mif.gz ]; then
    if [ ! -d unbiased ]; then mkdir unbiased; fi
    dwibiascorrect ants -nthreads $threads -bias unbiased/bias.mif.gz $dwi.mif.gz ${dwi}_unbiased.mif.gz
fi

# Brain mask estimation
if [ ! -f mask.mif.gz ]; then
    dwiextract -shells 1000 ${dwi}_unbiased.mif.gz - | mrmath -force -axis 3 - mean meanb1000tmp.nii.gz
    # Now create a set of BET-masks
    for fvalue in 30 35 40 45; do 
        bet meanb1000tmp.nii.gz meanb1000tmp_0p${fvalue} -R -m -f 0.$fvalue
    done
    # Check result and choose the appropriate mask
    echo "1. Check the results to decide the best BET f-value"
    echo    "mrview meanb1000tmp.nii.gz \
            -roi.load meanb1000tmp_0p30_mask.nii.gz -roi.opacity 0.5 \
            -roi.load meanb1000tmp_0p35_mask.nii.gz -roi.opacity 0.5 \
            -roi.load meanb1000tmp_0p40_mask.nii.gz -roi.opacity 0.5 \
            -roi.load meanb1000tmp_0p45_mask.nii.gz -roi.opacity 0.5 \
            -mode 2"
    echo "2. Choose the best mask and
                - save this as mask.mif.gz (mrconvert BET-mask.)
                - delete the tmp-files 
                - put the BET f-value into QC_dwi.csv-file"
    echo "3. Run this script again"
    exit;
fi

# last file in the processing
dwipreproclast=${dwi}_unbiased.mif.gz

cd $currdir

##################################################################################
## 4. B0-normalisation (individual/participant level)
cd $datadir/dwi

echo "Normalisation (participant level), meanb0 generation and tensor estimation"

# Create symbolic links to last file in preproc and mask.mif.gz and put this in $datadir
#ln -s preproc/$dwipreproclast dwi_preproc.mif.gz
# symbolic links do not work with rsync, so better to hard copy using mrconvert to retain command history
mrconvert preproc/$dwipreproclast dwi_preproc.mif.gz
#ln -s preproc/mask.mif.gz mask.mif.gz
mrconvert preproc/mask.mif.gz mask.mif.gz

dwi=dwi_preproc

# B0-normalisation
if [ ! -f ${dwi}_norm-ind.mif.gz ]; then
    dwinormalise individual -nthreads $threads $dwi.mif.gz mask.mif.gz ${dwi}_norm-ind.mif.gz
fi

dwi=dwi_preproc_norm-ind
cd $currdir

##################################################################################
# 5. meanb0, meanb1000 and meanb2600 generation
cd $datadir/dwi

if [ ! -f meanb0.mif.gz ]; then
    dwiextract -bzero $dwi.mif.gz - |  mrmath -force -axis 3 - mean meanb0.mif.gz
    mrcalc meanb0.mif.gz mask.mif.gz -mul meanb0_brain.mif.gz
fi
if [ ! -f meanb1000.mif.gz ]; then
    dwiextract -shells 1000  $dwi.mif.gz - |  mrmath -force -axis 3 - mean meanb1000.mif.gz
    mrcalc meanb1000.mif.gz mask.mif.gz -mul meanb1000_brain.mif.gz
fi
if [ ! -f meanb2600.mif.gz ]; then
    dwiextract -bzero $dwi.mif.gz - |  mrmath -force -axis 3 - mean meanb2600.mif.gz
    mrcalc meanb2600.mif.gz mask.mif.gz -mul meanb2600_brain.mif.gz
fi
    echo "Visually check the meann b-files"
    echo "mrview meanb*_brain.nii.gz -mode 2"

cd $currdir

##################################################################################
# 6. Calculate diffusion tensor and tensor metrics
cd $datadir/dwi

if [ ! -f dt.mif.gz ]; then
    dwiextract -shells 0,1000 $dwi.mif.gz - | dwi2tensor -mask mask.mif.gz - dt.mif.gz
    tensor2metric -force -fa fa.mif.gz -adc adc.mif.gz -rd rd.mif.gz -ad ad.mif.gz -vector ev.mif.gz dt.mif.gz
fi

cd $currdir
