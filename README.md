# NENAH-BIDS
A collaborate platform for streamlining a BIDS workflow for the NENAH study, on the linux workstation based at University of Southampton.

## Objectives
This project is to streamline a Brain Imaging Data Structure ([BIDS](https://bids.neuroimaging.io/)) workflow for Neurodevelopmental Trajectories and Neural Correlates in Children with Neonatal Hypoxic-Ischaemic Encephalopathy (NENAH), i.e. to put the NENAH data into a BIDS data structure, for [Quality Assessment](https://mriqc.readthedocs.io/en/latest/) and [customisable preprocessing](https://fmriprep.org/en/stable/), so as to keep track of the data quality continuously and quickly decide on recalls. Potentially, NeuroImaging Data Model ([NIDM](http://nidm.nidash.org/)) can be applied to turn BIDS datasets into Semantic-BIDS datasets with relevant clinical data, e.g. test scores.

## Tasks
 - Investigate if the Soton computer needs updating
      - (Follow with iSolution) OS: upgrade to <del>RH8 or</del> RH7
      - have ups power backup and a proper backup
 - <del>Connect to the Soton computer to establish a joint platform for working, where most of the processing will be run</del>
      - The common folder should have neuropaediatrics as a group which then will guide access rules
      - (Follow up with iSolution) Still have issues of SSH and permission to specific directory
 - For QA of sMRI (T1w) and fMRI: use [MRIQC](https://mriqc.readthedocs.io/en/stable/)
 - For dMRI: 
     - Make a pipeline that is BIDS compatible (fairly simple get data from BIDS /rawdata folder and just use non BIDS /derivatives folder as the output). A lot of what we want to do can be found in [BATMAN](https://mfr.osf.io/render?url=https://osf.io/pm9ba/?direct%26mode=render%26action=download%26mode=render)
     - Use the QC output that FSL eddy generates, or use eddy_quad. That means that we have to implement the pre-proc pipeline up and until EDDY (which have to be run with slice-to-volume correction), i.e. run eddy with flag that generates qc
 - BIDS conversion: 
     - set up using [heudiconv](https://heudiconv.readthedocs.io/en/latest/) (a heuristic-centric DICOM converter), mimicking the tutorial: http://reproducibility.stanford.edu/bids-tutorial-series-part-2a/
     - decide how to create slice_timing in the json-files
     - Harmonizing old (Pxxx) and new (NENAHxxx) naming. One subject will need to have one unique ID. To point out the repeat scan, use the session code in the BIDS (e.g. ses-1) to add subfolder under subject folder

## Relevant Resources
 - [BIDS and the NeuroImaging Data Model (NIDM)](https://f1000research.com/documents/8-1329)
 - dHCP: [Data Release 2019](https://drive.google.com/file/d/197g9afbg9uzBt04qYYAIhmTOvI3nXrhI/view), [Structural Pipeline](https://github.com/BioMedIA/dhcp-structural-pipeline)
 - [ABCD-ReproNim Course](https://www.abcd-repronim.org/index.html) ([syllabus](https://docs.google.com/document/d/1uStMP9DwdkVMsBVyudLywuz1ucTNttpzqN0UjIKssTA/edit?usp=sharing)): NIDM at [Week 6](https://abcd-repronim.github.io/materials/week-6/) - 6th November, 2020
 - [Neurostars](https://neurostars.org/): forum for BIDS and [ABCD-ReproNim](https://neurostars.org/c/abcd-repronim/232) discussions
 - [Winawer Lab](https://wikis.nyu.edu/display/winawerlab/home) [[Sample Data Pipeline](https://wikis.nyu.edu/display/winawerlab/Sample+Data+Pipeline)]
 - [Iridis: Singularity and Docker](https://hpc.soton.ac.uk/redmine/projects/iridis-5-support/wiki/Docker_and_Singularity), also watch [ABCD-ReproNim Week 3 videos](https://abcd-repronim.github.io/materials/week-3/)
