import os
import glob
import pandas as pd


# default params
studydir = os.getcwd()  # Assuming the script is run from the study directory
data_dir = os.path.join(studydir, "derivatives", "dMRI")  # Directory with all the subject folders
clinical_scores = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "clinical_scores", "RIO_NENAH_SchoolAge_memory_FSIQ_18July2024.xlsx")
skip_subjects_mri = os.path.join(studydir, "code", "NENAH-BIDS", "dMRI", "skip_subjects.txt")


# datadir=PATH, skip_subjects=LIST. Creates two dictionaries with NENAHXXX and NENAHCXXX as keys pointing to corresponding connecvitity matrix. 
def load_connectivity_matrices(data_dir, skip_subjects):
    control_matrices = {}
    subject_matrices = {}

    print("Loading connectivity matrices for eligible subjects:")
    with open(skip_subjects, 'r') as file:
        skip_subjects = [line.strip() for line in file]
    print("Skipped subjects from MRI data:")
    for sID in skip_subjects:
        print(sID)
    print("")
    
    for sub_dir in glob.glob(os.path.join(data_dir, "sub-*")):
        sub_id = os.path.basename(sub_dir)
        sID = sub_id.replace("sub-", "")
        
        if sID not in skip_subjects:
            con_path = os.path.join(sub_dir, "dwi", "connectome", "whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv")
            if os.path.isfile(con_path):
                matrix = pd.read_csv(con_path, header=None).values
                if "C" in sID:  # only controls have C in their ID
                    control_matrices[sID] = matrix
                else:
                    subject_matrices[sID] = matrix
    
    return control_matrices, subject_matrices

control_matrices, subject_matrices = load_connectivity_matrices(data_dir, skip_subjects_mri)



def load_clinical_data(clinical_scores_xl_file):
    df = pd.read_excel(clinical_scores_xl_file)
    # coloumns to use in analysis
    columns = ["Study.No", "INCLUDE_NENAH", "Group", "sex", "WISC_VSI_CompScore", "WISC_WMI_CompScore", "CMS_GenMem_IndScore", "RBMT_Total_Score"]
    clinical_data = df[columns]
    # filter out subjects not to be included 
    clinical_data = clinical_data[clinical_data["INCLUDE_NENAH"] == 1]
    clinical_excluded_subjects = clinical_data[clinical_data["INCLUDE_NENAH"] == 0]["Study.No"].tolist()
    return clinical_data, clinical_excluded_subjects

clinical_data, clinical_excluded_subjects = load_clinical_data(clinical_scores)



# print some data for checking
print("This is just some data for making sure everything seems fine:")
print("")
print("Excluding these subjects according to clinical scores:")
counter = 0
for sID in clinical_excluded_subjects:
    print(sID)
    counter+=1

print(f"Total= {counter} subjects excluded on basis of clinical data.")
print("")
print(f"Control group matrices: {len(control_matrices)}")
print(f"Subject group matrices: {len(subject_matrices)}")
print(clinical_data.head())

