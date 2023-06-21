## Data organisation
The study directory is `NENAH_BIDS` and is located in `/local/scratch/disk2/research/NENAH_BIDS`

The study directory `NENAH_BIDS` is [BIDS-organised](https://bids-specification.readthedocs.io/en/stable/):

```
/NENAH_BIDS
    ├── code        <= Where code goes (e.g. the the cloned github repo)
    ├── derivatives <= Processed data
    ├── dicomdir    <= "Raw" DICOM images 
    ├── sourcedata  <= "Organised" DICOM images 
    ├── rawdata     <= BIDS organised NIfTI images
    └── sequences   <= MRI protocols, gradient files etc
```

## Converting DCM data into BIDS-organised NIfTI-data
Bash and python scripts to convert DICOM data into BIDS-organised NIfTI data, in `/rawdata`.

All scripts working on the BIDS rawdata are organized in the `/bids` folder.

To complete the conversion: 

1. Run script `DcmDicomdir_to_DcmSourcedata.sh` \
This prepares the DICOMS in `/dicomdir` by re-naming and organizing them into `/sourcedata`

2. Run script `DcmSourcedata_to_NiftiRawdata.sh` \
This converts the dicoms in `/sourcedata` to BIDS-organised NIfTIs in `/rawdata` using the heudiconv routine.
The script runs
- `heudiconv` using a Docker container with rules set in the python file `nenah_heuristic.py`.
- BIDS validator (using a docker container)
- MRIQC (using a docker container)

3. Run correction scripts `run_fmap_add_Intededfor.py` to include entries for `Intended_for` in .JSON file

## Quality Control of NIfTI-data
After the conversion, a quality control (QC) is performed of the **sMRI**, **dMRI** and **fMRI** data.

Result are in dedicated book-keeping csv-files located in `/code/NENAH-BIDS/QC`.

Common for all QC-files, the 2nd column states if they have passed the QC-check
- PASS = 1 = Visually good quality rawdata
- Borderline = 0.5 = Visually not perfect rawdata and it is unclear whether it can be used
- FAIL = 0 = Visually poor quality rawdata and should not be used for further processing.

### Structural MRI (sMRI)
This is done by inspecting the T1-weighted images, both by inspecting the NIfTI-images and the output of `MRIQC`. 

Results are put in `code/NENAH-BIDS/QC/QC_MRIQC_anat.csv`:

### Diffusion  MRI (dMRI)
This is done by visually inspecting all the dMRI data using the script 

Results are put in `code/NENAH-BIDS/QC/QC_dwi.csv`:

NOTE - two columns describe which b0-volumes that will go into TOPUP are decided.  

### Resting-state fMRI (rs-fMRI)
This is done by inspecting the fMRI time-series and using output from `MRIQC`. 

Results are put in `code/NENAH-BIDS/QC/QC_MRIQC_func.csv`:
