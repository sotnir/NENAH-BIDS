import os
import glob
import pandas as pd


# default params
studydir = os.getcwd()  # Assuming the script is run from the study directory
data_dir = os.path.join(studydir, "dMRI")  # Directory with all the subject folders
clinical_scores = os.path.join(studydir, "analysis", "clinical_scores", "RIO_NENAH_SchoolAge_memory_FSIQ_18July2024.xlsx")
skip_subjects_mri = os.path.join(studydir, "code", "NENAH-BIDS", "dMRI", "skip_subjects.txt")


# datadir=PATH, skip_subjects=LIST
def load_connectivity_matrices(data_dir, skip_subjects):
    control_matrices = []
    subject_matrices = []
    subject_ids = []

    with open(skip_subjects, 'r') as file:
        skip_subjects = [line.strip() for line in file]
    print("Skipped subjects:")
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
                subject_ids.append(sID)
                if "C" in sID:  # only controls have C in their ID
                    control_matrices.append(matrix)
                else:
                    subject_matrices.append(matrix)
    
    return subject_ids, control_matrices, subject_matrices

subject_ids, control_matrices, subject_matrices = load_connectivity_matrices(data_dir, skip_subjects_mri)


def load_clinical_data(clinical_scores_file):
    df = pd.read_excel(clinical_scores_file)
    # coloumns to use in analysis
    columns_to_use = ["Study.No", "INCLUDE_NENAH", "Group", "sex", "WISC_VSI_CompScore", "WISC_WMI_CompScore", "CMS_GenMem_IndScore", "RBMT_Total_Score"]
    clinical_data = df[columns_to_use]
    # Filter out subjects not included in analysis
    clinical_data = clinical_data[clinical_data["INCLUDE_NENAH"] == 1]
    return clinical_data

clinical_data = load_clinical_data(clinical_scores)

# print some data for checking
print(f"Loaded {len(subject_ids)} subjects.")
print(f"Control group matrices: {len(control_matrices)}")
print(f"Subject group matrices: {len(subject_matrices)}")
print(clinical_data.head())

