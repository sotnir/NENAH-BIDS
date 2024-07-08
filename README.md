# NENAH-BIDS
A collaborate platform for streamlining a BIDS workflow for the NENAH study, on the linux workstation based at University of Southampton.

## Objectives
This project is to streamline a Brain Imaging Data Structure ([BIDS](https://bids.neuroimaging.io/)) workflow for Neurodevelopmental Trajectories and Neural Correlates in Children with Neonatal Hypoxic-Ischaemic Encephalopathy (NENAH), i.e. to put the NENAH data into a BIDS data structure, for [Quality Assessment](https://mriqc.readthedocs.io/en/latest/) and [customisable preprocessing](https://fmriprep.org/en/stable/), so as to keep track of the data quality continuously and quickly decide on recalls. Potentially, NeuroImaging Data Model ([NIDM](http://nidm.nidash.org/)) can be applied to turn BIDS datasets into Semantic-BIDS datasets with relevant clinical data, e.g. test scores.

## Workflows

![](https://raw.githubusercontent.com/yukaizou2015/NENAH-BIDS/main/img/workflows.png)

![image](https://github.com/sotnir/NENAH-BIDS/assets/160046020/33cf804b-9800-49c3-a6a1-3f5d198127e5)







## Tasks

All the tasks are organized into different Projects of this repository. Specifically: 
 - [BIDS data structure](https://github.com/yukaizou2015/NENAH-BIDS/projects/2) tracks the process of converting the raw DICOMs into a BIDS structured data set with relevant Metadata.
 - [Software management](https://github.com/yukaizou2015/NENAH-BIDS/projects/3) tracks study-specific software on the linux workstation.
 - Preprocessing of specific modalities will be tracked using [dMRI pipeline](https://github.com/yukaizou2015/NENAH-BIDS/projects/1) and [fMRI pipeline](https://github.com/yukaizou2015/NENAH-BIDS/projects/4).

BIDS conversion is set up using [heudiconv](https://heudiconv.readthedocs.io/en/latest/) (a heuristic-centric DICOM converter), mimicking the tutorial [here](http://reproducibility.stanford.edu/bids-tutorial-series-part-2a/).

For quality assessment of sMRI and rs-fMRI, [MRIQC](https://mriqc.readthedocs.io/en/stable/) is used. For dMRI, the QC outputs from FSL `eddy` or `eddy_quad` will be used. 

## Relevant Resources
 - [BIDS and the NeuroImaging Data Model (NIDM)](https://f1000research.com/documents/8-1329)
 - dHCP: [Data Release 2021](https://biomedia.github.io/dHCP-release-notes/), [Data Release 2019](https://drive.google.com/file/d/197g9afbg9uzBt04qYYAIhmTOvI3nXrhI/view), [Structural Pipeline](https://github.com/BioMedIA/dhcp-structural-pipeline); [Quality Control](https://biomedia.github.io/dHCP-release-notes/struct.html#struct-qc)
 - [ABCD-ReproNim Course](https://www.abcd-repronim.org/index.html) ([syllabus](https://docs.google.com/document/d/1uStMP9DwdkVMsBVyudLywuz1ucTNttpzqN0UjIKssTA/edit?usp=sharing)): NIDM at [Week 6](https://abcd-repronim.github.io/materials/week-6/) - 6th November, 2020
 - [Neurostars](https://neurostars.org/): forum for BIDS and [ABCD-ReproNim](https://neurostars.org/c/abcd-repronim/232) discussions
 - [Winawer Lab](https://wikis.nyu.edu/display/winawerlab/home) [[Sample Data Pipeline](https://wikis.nyu.edu/display/winawerlab/Sample+Data+Pipeline)]
 - [Iridis: Singularity and Docker](https://hpc.soton.ac.uk/redmine/projects/iridis-5-support/wiki/Docker_and_Singularity), also watch [ABCD-ReproNim Week 3 videos](https://abcd-repronim.github.io/materials/week-3/)
 - [QSIprep](https://qsiprep.readthedocs.io/en/latest/): Preprocessing and analysis of q-space images
 - [Neuroimaging and Data Science](http://neuroimaging-data-science.org/)
