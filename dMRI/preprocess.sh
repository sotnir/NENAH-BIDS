#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID [options]
Script to preprocess dMRI data 
1. MP-PCA Denoising and Gibbs Unringing 
2. TOPUP and EDDY for motion- and susceptebility image distortion correction
3. N4 biasfield correction, Normalisation

Arguments:
  sID    Subject ID   (e.g. NENAHC001) 
Options:
  -dwi			dMRI AP data (default: sourcedata/sub-sID/dwi/sub-sID_ses-ssID_dir-AP_dwi.nii.gz)
  -dwiPA	     	dMRI PA data, potentially for TOPUP  (default: sourcedata/sub-sID/dwi/sub-sID_ses-ssID_dir-PA_dwi.nii.gz)
  -seAP		     	Spin-echo field map AP, for TOPUP (default: sourcedata/sub-sID/fmap/sub-sID_ses-ssID_acq-se_dir-AP_epi.nii.gz)
  -sePA			Spin-echo field map PA, for TOPUP (default: sourcedata/sub-sID/fmap/sub-sID_ses-ssID_acq-se_dir-PA_epi.nii.gz)
  -d / -data-dir	<directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help	Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

currdir=`pwd`

# Defaults
dwi=sourcedata/sub-$sID/dwi/sub-${sID}_ses-${ssID}_dir-AP_dwi.nii.gz
dwiPA=sourcedata/sub-$sID/dwi/sub-${sID}_ses-${ssID}_dir-PA_dwi.nii.gz
seAP=sourcedata/sub-$sID/fmap/sub-${sID}_ses-${ssID}_acq-se_dir-AP_epi.nii.gz
sePA=sourcedata/sub-$sID/fmap/sub-${sID}_ses-${ssID}_acq-se_dir-PA_epi.nii.gz
datadir=derivatives/dMRI/sub-$sID

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift; shift
while [ $# -gt 0 ]; do
    case "$1" in
 -dwi) shift; dwi=$1; ;;
 -dwiAPsbref) shift; dwiAPsbref=$1; ;;
 -dwiPA) shift; dwiPA=$1; ;;
 -dwiPAsbref) shift; dwiPAsbref=$1; ;;
 -seAP) shift; seAP=$1; ;;
 -seAP) shift; sePA=$1; ;;
 -d|-data-dir)  shift; datadir=$1; ;;
 -h|-help|--help) usage; ;;
 -*) echo "$0: Unrecognized option $1" >&2; usage; ;;
 *) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
if [ ! -f $dwi ]; then dwi=""; fi
if [ ! -f $dwiAPsbref ]; then dwiAPsbref=""; fi
if [ ! -f $dwiPA ]; then dwiPA=""; fi
if [ ! -f $dwiPAsbref ]; then dwiPAsbref=""; fi
if [ ! -f $seAP ]; then seAP=""; fi
if [ ! -f $sePA ]; then sePA=""; fi

echo "Registration and sMRI-processing
Subject:       	$sID 
Session:       	$ssID
DWI (AP):	$dwi
DWI (PA):      	$dwiPA
SE fMAP (AP):  	$seAP        
SE fMAP (PA):  	$sePA        
Directory:     	$datadir 
$BASH_SOURCE   	$command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

echo dMRI preprocessing on subject $sID and session $ssID
script=`basename $0 .sh`
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo

##################################################################################
# 0. Copy to files to datadir/preproc (incl .json and bvecs/bvals files if present at original location)

if [ ! -d $datadir/preproc ]; then mkdir -p $datadir/preproc; fi

filelist="$dwi $dwiAPsbref $dwiPA $dwiPAsbref $seAP $sePA"
for file in $filelist; do
    filebase=`basename $file .nii.gz`;
    filedir=`dirname $file`
    cp $file $filedir/$filebase.json $filedir/$filebase.bval $filedir/$filebase.bvec $datadir/preproc/.

done

#Then update variables to only refer to filebase names (instead of path/file)
dwi=`basename $dwi .nii.gz` 
dwiPA=`basename $dwiPA .nii.gz`
seAP=`basename $seAP .nii.gz`
sePA=`basename $sePA .nii.gz`


##################################################################################
# 0. Create dwi.mif.gz to work with
cd $datadir/preproc

if [[ $dwi = "" ]];then
    echo "No dwi data provided";
    exit;
else
    # Create a dwi.mif.gz-file to work with
    if [ ! -f dwi.mif.gz ]; then
    mrconvert -json_import $dwi.json -fslgrad $dwi.bvec $dwi.bval $dwi.nii.gz dwi.mif.gz
    fi
fi

cd $currdir

##################################################################################
# 1. Do PCA-denoising and Remove Gibbs Ringing Artifacts
cd $datadir/preproc

# Directory for QC files
if [ ! -d denoise ]; then mkdir denoise; fi

# Perform PCA-denosing
if [ ! -f dwi_den.mif.gz ]; then
    echo Doing MP PCA-denosing with dwidenoise
    # PCA-denoising
    dwidenoise dwi.mif.gz dwi_den.mif.gz -noise denoise/dwi_noise.mif.gz;
    # and calculate residuals
    mrcalc dwi.mif.gz dwi_den.mif.gz -subtract denoise/dwi_den_residuals.mif.gz
    echo Check the residuals! Should not contain anatomical structure
fi

# Directory for QC files
if [ ! -d unring ]; then mkdir unring; fi

if [ ! -f dwi_den_unr.mif.gz ]; then
    echo Remove Gibbs Ringing Artifacts with mrdegibbs
    # Gibbs 
    mrdegibbs -axes 0,1 dwi_den.mif.gz dwi_den_unr.mif.gz
    #calculate residuals
    mrcalc dwi_den.mif.gz  dwi_den_unr.mif.gz -subtract unring/dwi_den_unr_residuals.mif.gz
    echo Check the residuals! Should not contain anatomical structure
fi

cd $currdir

##################################################################################
# 2. TOPUP and EDDY for Motion- and susceptibility distortion correction
cd $datadir/preproc

if [ ! -f seAP.mif.gz ]; then
    mrconvert -json_import $seAP.json $seAP.nii.gz seAP.mif.gz
fi
if [ ! -f sePA.mif.gz ]; then
    mrconvert -json_import $sePA.json $sePA.nii.gz sePA.mif.gz
fi
if [ ! -f seAPPA.mif.gz ]; then
    mrcat seAP.mif.gz sePA.mif.gz seAPPA.mif.gz
fi

# Create b0APPA.mif.gz to go into TOPUP
if [ ! -f b0APPA.mif.gz ];then
    echo "Create a PErevPE pair of SE images to use with TOPUP
1. Do this by put one good b0 from dir-AP_dwi and dir-PA_dwi into a file b0APPA.mif into $datadir/preproc
2. Run this script again.    
      "
    exit;
fi


# Do Topup and Eddy with dwipreproc
#
# use b0APPA.mif.gz (i.e. choose the two best b0s - could be placed first in dwiAP and dwiPA
#

if [ ! -f dwi_den_unr_eddy.mif.gz ];then
   dwifslpreproc -se_epi b0APPA.mif.gz -rpe_header -align_seepi -nocleanup \
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
cd $datadir/preproc

echo "Pre-processing with mask generation, N4 biasfield correction, Normalisation, meanb0 generation and tensor estimation"

# point to right filebase
dwi=dwi_den_unr_eddy

# Create mask and dilate (to ensure usage with ACT)
if [ ! -f mask.mif.gz ]; then
    dwiextract -bzero $dwi.mif.gz - | mrmath -force -axis 3 - mean meanb0tmp.nii.gz
    bet meanb0tmp meanb0tmp_brain -m -F -R
    # Check result
    mrview meanb0tmp.nii.gz -roi.load meanb0tmp_brain_mask.nii.gz -roi.opacity 0.5 -mode 2
    mrconvert meanb0tmp_brain_mask.nii.gz mask.mif.gz
    rm meanb0tmp*
fi

# Do B1-correction. Use ANTs N4
if [ ! -f  ${dwi}_N4.mif.gz ]; then
    threads=10;
    if [ ! -d N4 ]; then mkdir N4;fi
    dwibiascorrect ants -mask mask.mif.gz -bias N4/bias.mif.gz $dwi.mif.gz ${dwi}_N4.mif.gz
fi


# last file in the processing
dwipreproclast=${dwi}_N4.mif.gz

cd $currdir


##################################################################################
## 3. B0-normalise, create meanb0 and do tensor estimation

cd $datadir

# Create symbolic link to last file in /preproc and copy mask.mif.gz to $datadir
ln -s preproc/$dwipreproclast dwi_preproc.mif.gz
cp preproc/mask.mif.gz .
dwi=dwi_preproc

# B0-normalisation
if [ ! -f ${dwi}_norm.mif.gz ];then
    dwinormalise individual $dwi.mif.gz mask.mif.gz ${dwi}_norm.mif.gz
fi

# Extract mean B0
if [ ! -f meanb0.nii.gz ]; then
    dwiextract -bzero ${dwi}_norm.mif.gz - |  mrmath -force -axis 3 - mean meanb0.mif.gz
    mrcalc meanb0.mif.gz mask.mif.gz -mul meanb0_brain.mif.gz
    mrconvert meanb0.mif.gz meanb0.nii.gz
    mrconvert meanb0_brain.mif.gz meanb0_brain.nii.gz
    echo "Visually check the meanb0_brain"
    mrview meanb0_brain.nii.gz -mode 2
fi

# Calculate diffusion tensor and tensor metrics

if [ ! -f dt.mif.gz ]; then
    dwi2tensor -mask mask.mif.gz ${dwi}_norm.mif.gz dt.mif.gz
    tensor2metric -force -fa fa.mif.gz -adc adc.mif.gz -rd rd.mif.gz -ad ad.mif.gz -vector ev.mif.gz dt.mif.gz
fi

cd $currdir
