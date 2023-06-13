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
3. N4 biasfield correction
4. Normalisation
5. Creation of a mean B0 image (as average from normalised unwarped b0s)
6. Calculation of tensor and tensor maps (FA, MD etc)

Arguments:
  sID    Subject ID   (e.g. NENAHC001) 
Options:
  -dwiAP		dMRI AP data (default: rawdata/sub-sID/dwi/sub-sID_dir-AP_run-1_dwi.nii.gz)
  -dwiPA	     	dMRI PA data (default: rawdata/sub-sID/dwi/sub-sID_dir-PA_run-1_dwi.nii.gz)
  -b0APvol		b0 volume in dMRI AP data to use in TOPUP (default: 0)
  -b0PAvol		b0 volume in dMRI PA data to use in TOPUP (default: 0)
  -d / -data-dir	<directory> The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help	Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1
shift

currdir=$PWD

# Defaults
dwiAP=rawdata/sub-$sID/dwi/sub-${sID}_dir-AP_run-1_dwi.nii.gz
dwiPA=rawdata/sub-$sID/dwi/sub-${sID}_dir-PA_run-1_dwi.nii.gz
b0APvol=0
b0PAvol=0
datadir=derivatives/dMRI/sub-$sID
threads=10

# check whether the different tools are set and load parameters
studydir=$currdir;
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while [ $# -gt 0 ]; do
    case "$1" in
	-dwiAP) shift; dwiAP=$1; ;;
	-dwiPA) shift; dwiPA=$1; ;;
 	-b0APvol) shift; b0APvol=$1; ;;
	-b0PAvol) shift; b0PAvol=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else leave blank
if [ ! -f $dwiAP ]; then dwiAP=""; fi
if [ ! -f $dwiPA ]; then dwiPA=""; fi

echo "dMRI preprocessing
Subject:       	$sID 
DWI (AP):	$dwiAP
DWI (PA):      	$dwiPA
b0APvol:	$b0APvol
b0PAvol:	$b0PAvol	 
Directory:     	$datadir
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

# 0. Create dMRI mif-file in $datadir (importing .json and bvecs/bvals files)
if [ ! -d $datadir/dwi/orig ]; then mkdir -p $datadir/dwi/orig; fi

filelist="$dwiAP $dwiPA"
for file in $filelist; do
    filebase=`basename $file .nii.gz`;
    filedir=`dirname $file`
    cp $file $filedir/$filebase.json $filedir/$filebase.bval $filedir/$filebase.bvec $datadir/dwi/orig/.
done

#Then update variables to only refer to filebase names (instead of path/file)
dwiAP=`basename $dwiAP .nii.gz` 
dwiPA=`basename $dwiPA .nii.gz`

##################################################################################
# 0. Create dwi.mif.gz to work with in /preproc and b0APPA.mif.gz in /preproc/topup

if [ ! -d $datadir/dwi/preproc/topup ]; then mkdir -p $datadir/dwi/preproc/topup; fi

cd $datadir

if [[ $dwiAP = "" ]];then
    echo "No dwiAP data provided";
    exit;
else
    # Create a dwiAP.mif.gz-file to work with
    if [ ! -f dwi/preproc/dwiAP.mif.gz ]; then
	mrconvert -strides -1,2,3,4 -json_import dwi/orig/$dwiAP.json -fslgrad dwi/orig/$dwiAP.bvec dwi/orig/$dwiAP.bval dwi/orig/$dwiAP.nii.gz dwi/preproc/dwiAP.mif.gz
    fi
fi

if [[ $dwiPA = "" ]]; then
    echo "No dwiPA data provided";
    exit;
else
    # Create a dwiPA.mif.gz-file to work with
    if [ ! -f dwi/preproc/dwiPA.mif.gz ]; then
	mrconvert -strides -1,2,3,4 -json_import dwi/orig/$dwiPA.json -fslgrad dwi/orig/$dwiPA.bvec dwi/orig/$dwiPA.bval dwi/orig/$dwiPA.nii.gz dwi/preproc/dwiPA.mif.gz
    fi
fi

# Split data into data for different shells 
cd dwi/preproc

if [ ! -f dwi.mif.gz ]; then

    for dir in AP PA; do

	# 1. extract higher shells and put in a joint file
	dwiextract -shells 1000,2600 dwi$dir.mif.gz tmp_dwi${dir}_b1000b2600.mif
	
	# 2. extract the b0 that will be used for TOPUP by
	# a) noting correct volume
	if [ $dir == AP ]; then b0topup=$b0APvol; fi
	if [ $dir == PA ]; then b0topup=$b0PAvol; fi
	# b) and put in /topup/tmp_b0$dir.mif
	mrconvert -coord 3 $b0topup -axes 0,1,2 dwi$dir.mif.gz topup/tmp_b0$dir.mif
	# c) and extract b0s from dwi$dir.mif where the b0 for TOPUP will be placed first (by creating and an indexlist)
	indexlist=$b0topup;
	for index in `mrinfo -shell_indices dwi$dir.mif.gz | awk '{print $1}' | sed 's/\,/\ /g'`; do
	    if [ ! $index == $b0topup ]; then
		indexlist=`echo $indexlist,$index`;
	    fi
	done
	echo "Extracting b0-values in order $indexlist from dwi$dir.mif.gz, i.e. extracting volume $b0topup for TOPUP first";
	mrconvert -coord 3 $indexlist dwi$dir.mif.gz tmp_dwi${dir}_b0.mif
	
    done
    
    # Put everything into file dwi.mif.gz, with AP followed by PA volumes
    # FL 2021-12-20 - NOTE TOPUP and EDDY not working properly for dirPA, so only use dirAP to go into dwi.mif.gz
    mrcat -axis 3 tmp_dwiAP_b0.mif tmp_dwiAP_b1000b2600.mif tmp_dwiPA_b0.mif tmp_dwiPA_b1000b2600.mif dwi.mif.gz

    # clean-up
    rm tmp_dwi*.mif
    
fi

# Sort out topup/b0APPA.mif.gz
cd topup
if [ ! -f b0APPA.mif.gz ]; then
    mrcat -axis 3 tmp_b0AP.mif tmp_b0PA.mif b0APPA.mif.gz
    #clean-up
    rm tmp_dwi*_b0.mif
fi
    
cd $studydir

##################################################################################
# 1. Do PCA-denoising and Remove Gibbs Ringing Artifacts
cd $datadir/dwi/preproc

# Directory for MP PCA QC files
if [ ! -d denoise ]; then mkdir denoise; fi

# Perform PCA-denosing
if [ ! -f dwi_den.mif.gz ]; then
    echo Doing MP PCA-denosing with dwidenoise
    # PCA-denoising
    dwidenoise -nthreads $threads dwi.mif.gz dwi_den.mif.gz -noise denoise/dwi_noise.mif.gz;
    # and calculate residuals
    mrcalc dwi.mif.gz dwi_den.mif.gz -subtract denoise/dwi_den_residuals.mif.gz
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

cd $studydir

##################################################################################
# 2. TOPUP and EDDY for Motion- and susceptibility distortion correction
cd $datadir/dwi/preproc

if [ ! -d eddy ]; then mkdir eddy; fi

scratchdir=dwifslpreproc

# Do Topup and Eddy with dwipreproc and b0APPA.mif.gz as input
if [ ! -f dwi_den_unr_eddy.mif.gz ]; then
    dwifslpreproc -scratch $scratchdir \
		  -nocleanup \
		  -rpe_header -se_epi topup/b0APPA.mif.gz -align_seepi \
		  -topup_options " --iout=field_mag_unwarped" \
		  -eddy_slspec $studydir/sequences/slspec_NENAH_64_interleaved_slices.txt \
		  -eddy_options " --slm=linear --repol --mporder=8 --s2v_niter=10 --s2v_interp=trilinear --s2v_lambda=1 --estimate_move_by_susceptibility --mbs_niter=20 --mbs_ksp=10 --mbs_lambda=10" \
		  -eddyqc_all eddy \
		  dwi_den_unr.mif.gz \
		  dwi_den_unr_eddy.mif.gz;
   # or use -rpe_pair combo: dwifslpreproc DWI_in.mif DWI_out.mif -rpe_pair -se_epi b0_pair.mif -pe_dir ap -readout_time 0.72 -align_seepi
fi

# Now cleanup by transferring relevant files to topup folder and deleting scratch folder
mv eddy/quad ../../qc/.
cp $scratchdir/command.txt $scratchdir/log.txt $scratchdir/eddy_*.txt $scratchdir/applytopup_*.txt $scratchdir/slspec.txt eddy/.
mv $scratchdir/field_* $scratchdir/topup_* topup/.
rm -rf $scratchdir

cd $studydir

##################################################################################
# 3. Mask generation, N4 biasfield correction, meanb0 generation and tensor estimation
cd $datadir/dwi/preproc

echo "Pre-processing with mask generation, N4 biasfield correction, Normalisation, meanb0 generation and tensor estimation"

# point to right filebase
dwi=dwi_den_unr_eddy

#changed the code the mask from bet to dwi2mask and dwiexctract with b1000, moved bias correction before mask generation in the code. Now masks will be generated after bias correction
# Do B1-correction. Use ANTs N4
if [ ! -f  ${dwi}_N4.mif.gz ]; then
    if [ ! -d N4 ]; then mkdir N4; fi
    dwibiascorrect ants -nthreads $threads -bias N4/bias.mif.gz $dwi.mif.gz ${dwi}_N4.mif.gz
fi

# Create mask and dilate (to ensure usage with ACT)
if [ ! -f mask.mif.gz ]; then
    dwiextract -b 1000 ${dwi}_N4.mif.gz - | mrmath -force -axis 3 - mean meanb1000tmp.mif.gz
    dwi2mask meanb1000tmp.mif.gz meanb1000tmp_brain.nii.gz
    # Check result
    echo Check the results
    echo "mrview meanb1000tmp.mif.gz -roi.load meanb1000tmp_brain_mask.nii.gz -roi.opacity 0.5 -mode 2"
   mrconvert meanb1000tmp_brain_mask.nii.gz mask.mif.gz
    rm meanb1000tmp*
fi

# last file in the processing
dwipreproclast=${dwi}_N4.mif.gz

cd $currdir

##################################################################################
## 3. B0-normalise, create meanb0 and do tensor estimation

cd $datadir/dwi

mrconvert preproc/$dwipreproclast dwi_preproc.mif.gz
mrconvert preproc/mask.mif.gz mask.mif.gz
dwi=dwi_preproc

# B0-normalisation
if [ ! -f ${dwi}_inorm.mif.gz ]; then
    dwinormalise individual -nthreads $threads $dwi.mif.gz mask.mif.gz ${dwi}_inorm.mif.gz
fi

# Extract mean b0, b1000 and b2600
for bvalue in 0 1000 2600; do
    bfile=meanb$bvalue

    if [ $bvalue == 0 ]; then
	if [ ! -f $bfile.mif.gz]; then
	    dwiextract -shells $bvalue ${dwi}_inorm.mif.gz - |  mrmath -force -axis 3 - mean $bfile.mif.gz
	fi
    fi
    if [ ! -f ${bfile}_brain.mif.gz ]; then
	dwiextract -shells $bvalue ${dwi}_inorm.mif.gz - |  mrmath -force -axis 3 - mean - | mrcalc - mask.mif.gz -mul ${bfile}_brain.mif.gz
	echo "Visually check the ${bfile}_brain.mif.gz"
	echo mrview ${bfile}_brain.mif.gz -mode 2
    fi
done

# Calculate diffusion tensor and tensor metrics

if [ ! -f dt.mif.gz ]; then
    dwi2tensor -mask mask.mif.gz ${dwi}_inorm.mif.gz dt.mif.gz
    tensor2metric -force -fa fa.mif.gz -adc adc.mif.gz -rd rd.mif.gz -ad ad.mif.gz -vector ev.mif.gz dt.mif.gz
fi

cd $studydir
