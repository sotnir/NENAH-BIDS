Bash and python scripts to convert DICOM data into BIDS-organised NIfTI data, in `/rawdata`.

All scripts working on the BIDS rawdata are organized in the `/bids` folder.

To complete the conversion: 

1. Run script `DcmDicomdir_to_DcmSourcedata.sh` \
This prepares the DICOMS by re-naming and organizing them into `/sourcedata`

2. Run script `DcmSourcedata_to_NiftiRawdata.sh` \
This converts the dicoms in `/sourcedata` to BIDS-organised NIfTIs in `/rawdata`using the heudiconv routine. 
- `heudiconv` is run with using a Docker container using rules set in the python file `nenah_heuristic.py`
- The script also makes a BIDS-validation and MRIQC

3. (In testing) Run fMRIPrep
- `run_fmap_add_IntendedFor.sh` is a bash script that executes `fmap_add_IntendedFor.py`, which updates the corresponding `.json` file of field maps in `/fmap`. This is to prepare running fMRIPrep by performing susceptibility distortion correction.
