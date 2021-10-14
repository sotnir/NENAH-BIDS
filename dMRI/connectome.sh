#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID sessionID [options]
Creates connectome based on SIFT whole-brain tractogram
Arguments:
  sID				Subject ID (e.g. NENAHCO12) 

Options:
  -tract			SIFT whole-brain tractogram to use (default: derivatives/dMRI/sub-$\sID/tractography/whole_brain_10M_sift.tck)
  -label			Segmentation/Parcellation image in dMRI space (default: derivatives/dMRI/sub-$\sID/anat/fs-segm_aparc+aseg_dwi-space.mif.gz)
  -threads			Number of CPUs (default: 10)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-$\sID)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ $# -ge 1 ] || { usage; }
command=$@
sID=$1

currdir=`pwd`

# Defaults
datadir=derivatives/dMRI/sub-$sID
tract=derivatives/dMRI/sub-$sID/tractography/whole_brain_10M_sift.tck
label=derivatives/dMRI/sub-$sID/anat/fs-segm_aparc+aseg_space-dwi.mif.gz
threads=10

shift;
while [ $# -gt 0 ]; do
    case "$1" in
	-tract) shift; tract=$1; ;;
	-label) shift; label=$1; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Creation off Whole-brain ACT tractography
Subject:       	        $sID 
Tract:			$tract
Labels:			$label
Threads:		$threads
Directory:     		$datadir 
$BASH_SOURCE   		$command
----------------------------"

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

script=`basename $0 .sh`
echo Executing: $codedir/$script.sh $command > ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_ses-${ssID}_sMRI_$script.log 2>&1
echo


##################################################################################
## 0. Copy to files to relevant $atlas location $datadir/anat folder (incl .json if present at original location)

tractdir=tractography
if [ ! -d $datadir/$tractdir ]; then mkdir -p $datadir/$tractdir; fi

# Tractogram will go into tractography folder
tractbase=`basename $tract .tck`
if [ ! -f $datadir/$tractdir/$tractbase.tck ];then
    cp $tract $datadir/$tractdir/.
fi

# Labels file will go into anat folder
labeldir=anat
if [ ! -d $datadir/$labeldir ]; then mkdir -p $datadir/$labeldir; fi									  
labelbase=`basename $label`
if [ ! -f $datadir/$labeldir/$labelbase ];then
    cp $file $datadir/$labeldir/.
fi

# Update variables to point at corresponding filebases in $datadir
segm=`basename $segm .mif.gz`
label=`basename $label .mif.gz`

##################################################################################
## 1. Create MRtrix compatible segmentation from FS segmentation

cd $datadir

# put these in connectome folder
if [ ! -d connectome ]; then mkdir connectome; fi

# first use labelconvert to extract connectome structures and put into a continuous LUT and make sure 3D and datatype uint32
    #labelconvert -force $seg_in $lut_in $lut_out - | mrmath -datatype uint32 -force -axis 3 - mean $seg_out
    # then use mrthreshold to get rid of entries past $thr and make sure $seg_out is 3D and with integer datatype# NOT needed since all $seg_out does not need to be thresholded
#mrthreshold -abs $thr -invert $seg_out - | mrcalc -force -datatype uint32 - $seg_out -mul - | mrmath -force -axis 3 -datatype uint32 - mean $seg_out

MRTRIXHOME=`which mrview | sed 's/\/bin\/mrview//g'`
if [ ! -f connectome/${label}_nodes.mif.gz ]; then
    labelconvert anat/$label.mif.gz $FREESURFER_HOME/FreeSurferColorLUT.txt $MRTRIXHOME/share/mrtrix3/labelconvert/fs_default.txt connectome/${label}_nodes.mif.gz
fi

if [ ! -f connectome/${label}_nodes_fixSGM.mif.gz ]; then
    labelsgmfix connectome/${label}_nodes.mif.gz anat/t1w_brain_space-dwi.mif.gz $MRTRIXHOME/share/mrtrix3/labelconvert/fs_default.txt connectome/${label}_nodes_fixSGM.mif.gz -premasked -sgm_amyg_hipp -nthreads $threads
fi

cd $currdir

##################################################################################
## 2. Create connectome

cd $datadir

# Generate connectome
if [ ! -f connectome/${tractbase}_${label}_Connectome.csv ]; then
    # Create connectome using ${tractbase}.tck
    echo "Creating $label connectome from ${tractbase}.tck"
    tck2connectome -symmetric -zero_diagonal -scale_invnodevol -out_assignments connectome/assignments_${tractbase}_${label}_Connectome.csv tractography/$tractbase.tck connectome/${label}_nodes_fixSGM.mif.gz connectome/${tractbase}_${connectome}_Connectome.csv    
fi

cd $currdir
