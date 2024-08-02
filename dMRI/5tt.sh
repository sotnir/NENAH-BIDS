#!/bin/bash
# NENAH Study
#
usage()
{
  base=$(basename "$0")
  echo "usage: $base subjectID [options]
Create 5tt image from FreeSurfer and HIPS-THOMAS segmentation and keep in anatomical space or transform into DWI-space
(requires that registration.sh has been run to create transformation between T1w <-> dMRI)

Arguments:
  sID				Subject ID (e.g. NENAHC012) 
  space             Choose whether output to dwi-space or anat-space
Options:
  -segm				Segmentation from FreeSurfer (default: derivatives/dMRI/sub-ID/dwi/aparc+aseg_thomas-thalamic_gmfix.mif.gz)
  -d / -data-dir  <directory>   The directory used to output the preprocessed files (default: derivatives/dMRI/sub-sID)
  -h / -help / --help           Print usage.
"
  exit;
}

################ ARGUMENTS ################

# check whether the different tools are set and load parameters
codedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ $# -ge 2 ] || { usage; }
command=$@
sID=$1
space=$2
shift 2

studydir=`pwd`

# Defaults

datadir=derivatives/dMRI/sub-$sID
segm="${datadir}/anat/aparc+aseg_thomas-thalamic_gmfix.mif.gz"

while [ $# -gt 0 ]; do
    case "$1" in
	-segm) shift; segm=$; ;;
	-d|-data-dir)  shift; datadir=$1; ;;
	-h|-help|--help) usage; ;;
	-*) echo "$0: Unrecognized option $1" >&2; usage; ;;
	*) break ;;
    esac
    shift
done

echo "Create 5tt image from FreeSurfer and HIPS-THOMAS segmentation and output in ${space}-space
Subject:       	   $sID 
FS segm:	       $segm
Space:             $space
Directory:     	   $datadir 
$BASH_SOURCE   	   $command
----------------------------"

if [[ "$space" != "dwi" && "$space" != "anat" ]]; then
    echo "Please enter a valid space. (eg. dwi or anat)"
    usage
fi

logdir=$datadir/logs
if [ ! -d $datadir ];then mkdir -p $datadir; fi
if [ ! -d $logdir ];then mkdir -p $logdir; fi

script=`basename $0 .sh`
echo Executing: $codedir/$script.sh $command > ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo "Printout $script.sh" >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
cat $codedir/$script.sh >> ${logdir}/sub-${sID}_dMRI_$script.log 2>&1
echo

##################################################################################
# 0. Put files in $datadir

if [ ! -d $datadir/anat ]; then mkdir -p $datadir/anat; fi

##################################################################################
# 1. Generate 5TT image and files for visualisation 
#




if [ "$space" == "dwi" ]; then
    if [ ! -d $datadir/dwi/5tt ]; then mkdir -p $datadir/dwi/5tt; fi
    cd $datadir/dwi/5tt


    # Generate 5tt and transform into dMRI space directly
    if [ ! -f 5tt_space-dwi.mif.gz ]; then
        mrtransform ../../anat/fs-segm_aparc+aseg.nii.gz -linear ../../xfm/dwi_2_t1w_mrtrix-bbr.mat ../../anat/fs-segm_aparc+aseg_space-dwi.mif.gz -inverse
        5ttgen -force freesurfer -sgm_amyg_hipp ../../anat/fs-segm_aparc+aseg_space-dwi.mif.gz 5tt_space-dwi.mif.gz
    fi

    # Create for visualisation 
    if [ ! -f 5tt_space-dwi_vis.mif.gz ]; then
        5tt2vis 5tt_space-dwi.mif.gz 5tt_space-dwi_vis.mif.gz
    fi
    # and GM/WM boundary
    if [ ! -f 5tt_space-dwi_gmwm.mif.gz ]; then
        5tt2gmwmi 5tt_space-dwi.mif.gz 5tt_space-dwi_gmwmi.mif.gz
    fi
fi

if [ "$space" == "anat" ]; then

    if [ ! -d "$datadir/anat/5tt" ]; then 
        mkdir -p "$datadir/anat/5tt"
    fi
    cd $datadir/anat/5tt

    # inputs
    segm_LUT="../../../../../code/NENAH-BIDS/label_names/fs_thomas-thalamic_LUT.txt"
    convert="../../../../../code/NENAH-BIDS/label_names/convert_thomas-thalamic_to_fs.txt"
    segm="../aparc+aseg_thomas-thalamic.mif.gz" # change back to aparc+aseg_thomas-thamalic_gmfix in future


    if [ ! -f "5tt_space-anat.mif.gz" ]; then
        labelconvert $segm $segm_LUT $convert thomas-thalamic_is_fs_tmp.mif.gz
        5ttgen -force freesurfer -sgm_amyg_hipp thomas-thalamic_is_fs_tmp.mif.gz 5tt_space-anat.mif.gz
        if [[ -f "5tt_space-anat.mif.gz" ]]; then
            echo ""
            echo "5ttgen for $sID complete!"
            echo "Removing tmp. files"
            rm thomas-thalamic_is_fs_tmp.mif.gz
        else
            echo ""
            echo "5ttgen couldn't be done for $sID"
            echo ""
        fi
    fi

        # Create for visualisation 
    if [[ ! -f "5tt_space-anat_vis.mif.gz" && -f "5tt_space-anat.mif.gz" ]]; then
        5tt2vis -force 5tt_space-anat.mif.gz 5tt_space-anat_vis.mif.gz
    fi
    # and GM/WM boundary
    if [[ ! -f "5tt_space-anat_gmwmi.mif.gz" && -f "5tt_space-anat.mif.gz" ]]; then
        5tt2gmwmi -force 5tt_space-anat.mif.gz 5tt_space-anat_gmwmi.mif.gz
    fi
fi


cd $studydir
