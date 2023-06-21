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

## Converting DCM data into BIDS-organised NIfTI-data in  `NENAH_BIDS`
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
