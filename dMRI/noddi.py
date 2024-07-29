# Script for calculating NODDI maps using the AMICO python package

import argparse
import os
import pathlib
import subprocess

parser = argparse.ArgumentParser(description='Script for performing AMICO NODDI estimation. Output written into folder AMICO/NODDI_dPar')
parser.add_argument('--sID', help='Subject ID (e.g. NENAHC004)', required=True)
args = vars(parser.parse_args())

sID = args['sID']
studydir = os.getcwd()
datadir = os.path.join(studydir, "derivatives", "dMRI", sID)
dpar = 1.7e-3

# define paths to necessary files
dwi = os.path.join(datadir, "dwi", "dwi_preproc_hires.mif.gz")
mask = os.path.join(datadir, "dwi", "mask_space-dwi_hires.mif.gz")
bvec = os.path.join(datadir, "dwi", "orig", f"{sID}_dir-AP_run-1_dwi.bvec")
bval = os.path.join(datadir, "dwi", "orig", f"{sID}_dir-AP_run-1_dwi.bval")

# create output directory for NODDI results
output_dir = os.path.join(datadir,'dwi', 'noddi')
os.makedirs(output_dir, exist_ok=True)

# converting MRtrix files to NIfTI format
dwi_nii = os.path.join(output_dir, "dwi_preproc_hires.nii")
mask_nii = os.path.join(output_dir, "mask_space-dwi_hires.nii")

subprocess.run(['mrconvert', dwi, dwi_nii])
subprocess.run(['mrconvert', mask, mask_nii])

import amico
import numpy as np



# Setup AMICO once (if not already done)
# amico.setup() # Uncomment if AMICO setup is needed

# save gradient scheme
scheme_file = os.path.join(output_dir, f"{sID}_dwi.scheme")
amico.util.fsl2scheme(bval, bvec, scheme_file)

# initialize the Evaluation object
ae = amico.Evaluation(studydir, os.path.join("derivatives", "dMRI", sID))

# load data
ae.load_data(
    dwi_filename=dwi_nii,
    scheme_filename=scheme_file,
    mask_filename=mask_nii,
    b0_thr=0
)

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