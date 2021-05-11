Bash and python scripts to convert DICOM data into BIDS-organised NIfTI data.

The folder structure will be
- Original dicoms in `/dicomdir`
- Re-named and re-arranged dicoms in are `/sourcedata`, which is the BIDS sourcedata-folder
- BIDS-organised NIfTIs in `/rawdata`

To complete the conversion: 

1. Run script `DcmDicomdir_to_DcmSourcedata.sh` \
This re-names the dicoms and sorts them into `/sourcedata` 

2. Run script `DcmSourcedata_to_NiftiRawdata.sh` \
This converts the dicoms in `/sourcedata` to BIDS-organised NIfTIs in `/rawdata`using the heudiconv routine. 
- `heudiconv` is run with using a Docker container using rules set in the python file `nenah_heuristic.py`
- The script also makes a BIDS-validation and MRIQC
