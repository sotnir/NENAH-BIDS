# NENAH-BIDS
A collaborate platform for streamlining a BIDS workflow for the NENAH study, on the linux workstation based at University of Southampton.

## Objectives
This project is to streamline a Brain Imaging Data Structure ([BIDS](https://bids.neuroimaging.io/)) workflow for Neurodevelopmental Trajectories and Neural Correlates in Children with Neonatal Hypoxic-Ischaemic Encephalopathy (NENAH), i.e. to put the NENAH data into a BIDS data structure, for [Quality Assessment](https://mriqc.readthedocs.io/en/latest/) and [customisable preprocessing](https://fmriprep.org/en/stable/), so as to keep track of the data quality continuously and quickly decide on recalls. Potentially, NeuroImaging Data Model ([NIDM](http://nidm.nidash.org/)) can be applied to turn BIDS datasets into Semantic-BIDS datasets with relevant clinical data, e.g. test scores.

## Tasks (in transition to Projects/Issues)
 - Restructuring the QC workflow by editing the current projects (BIDS, dMRI, fMRI, sMRI?):
 - [MRIQC](https://mriqc.readthedocs.io/en/stable/): For QA of sMRI (T1w) and fMRI
 - For dMRI: 
     - Make a pipeline that is BIDS compatible (fairly simple get data from BIDS /rawdata folder and just use non BIDS /derivatives folder as the output). A lot of what we want to do can be found in [BATMAN](https://mfr.osf.io/render?url=https://osf.io/pm9ba/?direct%26mode=render%26action=download%26mode=render)
     - Use the QC output that FSL eddy generates, or use eddy_quad. That means that we have to implement the pre-proc pipeline up and until EDDY (which have to be run with slice-to-volume correction), i.e. run eddy with flag that generates qc
 - BIDS conversion: 
     - set up using [heudiconv](https://heudiconv.readthedocs.io/en/latest/) (a heuristic-centric DICOM converter), mimicking the tutorial: http://reproducibility.stanford.edu/bids-tutorial-series-part-2a/

## Relevant Resources
 - [BIDS and the NeuroImaging Data Model (NIDM)](https://f1000research.com/documents/8-1329)
 - dHCP: [Data Release 2019](https://drive.google.com/file/d/197g9afbg9uzBt04qYYAIhmTOvI3nXrhI/view), [Structural Pipeline](https://github.com/BioMedIA/dhcp-structural-pipeline); [Quality Control](https://biomedia.github.io/dHCP-release-notes/struct.html#struct-qc)
 - [ABCD-ReproNim Course](https://www.abcd-repronim.org/index.html) ([syllabus](https://docs.google.com/document/d/1uStMP9DwdkVMsBVyudLywuz1ucTNttpzqN0UjIKssTA/edit?usp=sharing)): NIDM at [Week 6](https://abcd-repronim.github.io/materials/week-6/) - 6th November, 2020
 - [Neurostars](https://neurostars.org/): forum for BIDS and [ABCD-ReproNim](https://neurostars.org/c/abcd-repronim/232) discussions
 - [Winawer Lab](https://wikis.nyu.edu/display/winawerlab/home) [[Sample Data Pipeline](https://wikis.nyu.edu/display/winawerlab/Sample+Data+Pipeline)]
 - [Iridis: Singularity and Docker](https://hpc.soton.ac.uk/redmine/projects/iridis-5-support/wiki/Docker_and_Singularity), also watch [ABCD-ReproNim Week 3 videos](https://abcd-repronim.github.io/materials/week-3/)
 - [QSIprep](https://qsiprep.readthedocs.io/en/latest/): Preprocessing and analysis of q-space images
