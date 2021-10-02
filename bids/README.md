Bash and python scripts to convert DICOM data into BIDS-organised NIfTI data, in `/rawdata`.

All scripts working on the BIDS rawdata are organized in the `/bids` folder.

To complete the conversion: 

1. Run script `DcmDicomdir_to_DcmSourcedata.sh` \
This prepares the DICOMS by re-naming and organizing them into `/sourcedata`

2. Run script `DcmSourcedata_to_NiftiRawdata.sh` \
This converts the dicoms in `/sourcedata` to BIDS-organised NIfTIs in `/rawdata`using the heudiconv routine. 
- `heudiconv` is run with using a Docker container using rules set in the python file `nenah_heuristic.py`

3. Run correction scripts to make the /rawdata BIDS compliant and include slice_time_corrections and Intended_for

4. Run BIDS validator

5. Run MRIQC
