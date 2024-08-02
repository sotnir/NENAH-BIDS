# Script for calculating NODDI maps using the AMICO python package

import argparse
import os
import pathlib
import subprocess

# Usage
help_message = """
Scripts to calculate NODDI maps for subjects in the NENAH study.
Arguments: 
    sID         Subject ID (e.g. NENAHC004)

Options: 
    -h/-help /--help        

    --dpar     The axial diffusivity to use in the NODDI model (default: 1.7e-3)
 
The directories used are:
- The PWD as studydir (e.g. data/iridis/NENAH_BIDS)
- Datadir as path to subject data (default: studydir/derivatives/dMRI/sub-ID)
The files used are:
- dMRI MRtrix file (default: datadir/dwi/dwi_preproc_hires.mif.gz)
- Brain mask MRtrix file (default: datadir/dwi/mask_space-dwi_hires.mif.gz)

"""

# Argument parser setup
parser = argparse.ArgumentParser(description=help_message, formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('--sID', help='Subject ID (e.g. NENAHC004)', required=True)
parser.add_argument('--dpar', help='The axial diffusivity to use in the NODDI model (default: 1.7e-3)', required=False)
args = vars(parser.parse_args())



sID = args['sID']
studydir = os.getcwd()
datadir = os.path.join(studydir, "derivatives", "dMRI", f"sub-{sID}")
dpar = args['dpar'] if args['dpar'] is not None else 1.7e-3

# define paths to necessary files
dwi = os.path.join(datadir, "dwi", "dwi_preproc_hires.mif.gz")
mask = os.path.join(datadir, "dwi", "mask_space-dwi_hires.mif.gz")
meanb0_file = os.path.join(datadir, "dwi", "meanbo_dwi_preproc_hires.mif.gz")


# create output directory for NODDI results
output_dir = os.path.join(datadir,'dwi', 'noddi')

if not os.path.exists(output_dir):
    os.makedirs(output_dir, exist_ok=True)

os.makedirs(output_dir, exist_ok=True)

# converting MRtrix files to NIfTI format
dwi_nii = os.path.join(datadir,'dwi', "tmp_dwi_preproc_hires.nii")
mask_nii = os.path.join(datadir,'dwi', "tmp_mask_space-dwi_hires.nii")
meanb0_nii = os.path.join(datadir,'dwi', "tmp_meanb0_dwi_preproc_hires.nii")

# tmp
tmp_dwi_output = os.path.join(datadir,'dwi', "tmp_dwiextract_output.nii")


subprocess.run(['mrconvert', dwi, dwi_nii])
subprocess.run(['mrconvert', mask, mask_nii])
subprocess.run(['mrconvert', meanb0_file, meanb0_nii])

# generating bvecs/bvals from preproc_hires
bvec = os.path.join(datadir, "dwi", "tmp_dwi_preproc_hires.bvec")
bval = os.path.join(datadir, "dwi", "tmp_dwi_preproc_hires.bval")

subprocess.run(['dwiextract', dwi, tmp_dwi_output, '-export_grad_fsl', bvec, bval])



import amico
import numpy as np



# Setup AMICO once (if not already done)
#amico.setup()


# initialize the Evaluation object
ae = amico.Evaluation(studydir, os.path.join("derivatives", "dMRI",f"sub-{sID}"))

# save gradient scheme
scheme_file = os.path.join(output_dir, f"{sID}_dwi.scheme")
amico.util.fsl2scheme(bval, bvec, scheme_file)

# load data
ae.load_data(
    dwi_filename=tmp_dwi_output,
    scheme_filename=scheme_file,
    mask_filename=mask_nii,
    b0_thr=0
)

ae.DWI[:, :, :, 0] = nib.load(mean_b0_file).get_fdata()

# set the NODDI model with specific parameters
ae.set_model("NODDI")
ae.model.set(
    dPar=dpar,
    dIso=3.0E-3,
    IC_VFs=np.linspace(0.1, 0.99, 12),
    IC_ODs=np.hstack((np.array([0.03, 0.06]), np.linspace(0.09, 0.99, 10))),
    isExvivo=False
)

# generate and load kernels
ae.generate_kernels(regenerate=True)
ae.load_kernels()

# fit the NODDI model to the data
ae.fit()

# save the results
ae.save_results(output_dir)

