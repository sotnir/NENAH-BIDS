#!/bin/bash
# Zagreb Collab dhcp - PMR
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base sID ssID [options]
- do motion-correction (not yet implemented)
- make high-resolution versions T2w MCRIB \
- create relevant brain masks for neonatal-segmentation \
Arguments:
  sID				Subject ID (e.g. PMRXYZ)
  ssID				Session ID (e.g. MR2) 
Options:
  -T2				T2 image (default: sourcedata/sub-sID/ses-ssID/anat/sub-sID_ses-ssID_T2w.nii.gz)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/sMRI/preproc)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1
ssID=$2

# Defaults
currdir=`pwd`
t2w=sourcedata/sub-$sID/ses-$ssID/anat/sub-${sID}_ses-${ssID}_T2w.nii.gz
datadir=derivatives/sMRI/preproc/sub-$sID/ses-$ssID
# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

shift
while [ $# -gt 0 ]; do
    case "$1" in
	-T2) shift; t2w=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

# Check if images exist, else put in No_image
if [ ! -f $tw2 ]; then tw2=""; fi

echo "Preproc for sMRI-processing
Subject:       $sID 
T2:	       $t2w 
Directory:     $datadir 
$BASH_SOURCE   $command
----------------------------"

logdir=derivatives/preprocessing_logs/sub-$sID/ses-$ssID
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

echo sMRI preprocessing on subject $sID
script=`basename $0 .sh`
echo Executing: $codedir/sMRI/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo

##################################################################################
# 0. Copy to file to datadir 
if [ ! -d $datadir ]; then mkdir -p $datadir; fi

cp $t2w $datadir/.

#Then update to refer to filebase names (instead of path/file)
t2w=`basename $t2w .nii.gz` #sub-${sID}_ses-${ssID}_T2w

##################################################################################
# 1. Motion-correction
# Not yet implememented

##################################################################################
# 2. Upsample T2w (required for DrawEM neonatal-segmentation)

cd $datadir

image=$t2w;
if [[ $image = "" ]]; then echo "No T2w image"; exit;
else
    if [[ $image = sub-${sID}_ses-${ssID}_T2w ]] || [[ $image = sub-${sID}_ses-${ssID}_acq-spc_T2w ]]; then
	# BIDS compliant highres name 
	highres=`echo $image | sed 's/\_T2w/\_desc\-hires\_T2w/g'`
    else
	# or else, just add desc-highres before the file name
	highres=desc-hires_${image}
    fi
    # Do interpolation (spline)
    if [ ! -f $highres.nii.gz ]; then
	flirt -in $image.nii.gz -ref $image.nii.gz -applyisoxfm 0.68 -nosearch -out $highres.nii.gz -interp spline
    fi
    # and update t2w to point to highres
    t2w=$highres;
fi

cd $currdir

##################################################################################
## 3. Create brain mask in T2w-space
cd $datadir
if [ ! -f sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz ];then
    
    # bet T2w using -F flag
    bet ${t2w}.nii.gz ${t2w}_brain.nii.gz -m -R -F #f 0.3
    mv ${t2w}_brain_mask.nii.gz sub-${sID}_ses-${ssID}_space-T2w_mask.nii.gz

    # Clean-up
    rm *brain*
fi
cd $currdir

##################################################################################
## 3. Finish by creating symbolic link to relevant preprocessed file
cd $datadir

if [ ! -f sub-${sID}_ses-${ssID}_desc-preproc_T2w.nii.gz ]; then 
	# create symbolic link to preproc file
	ln -s $t2w.nii.gz sub-${sID}_ses-${ssID}_desc-preproc_T2w.nii.gz;
fi
	
cd $currdir
