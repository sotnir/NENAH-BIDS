import os
import glob
import pandas as pd

#Borde göra en function som bestämmer listan included_subjects, och sedan göra clinical data och con matriser från den listan istället! Gör det simpelt. 



# default params
studydir = os.getcwd()  # Assuming the script is run from the study directory
data_dir = os.path.join(studydir, "derivatives", "dMRI")  # Directory with all the subject folders
clinical_scores = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "clinical_data", "RIO_NENAH_SchoolAge_memory_FSIQ_18July2024.xlsx")
mri_excluded_subjects = os.path.join(studydir, "code", "NENAH-BIDS", "analysis","clinical_data" "mri_excluded_subjects.txt")
subjects_no_clinical_data= os.path.join(studydir, "code", "NENAH-BIDS", "analysis","clinical_data" "clinical_excluded_subjects.txt")
dataset = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "clinical_data", "RIO_NENAH_SchoolAge_23July2024.xlsx")



def exclude_subjects(excl_mri, clinical_data):
    df = pd.read_excel(clinical_data)

    clinical_included_subjects = df[df["INCLUDE_NENAH"] == 1]["Study.No"].tolist()
    clinical_excluded_subjects = df[df["INCLUDE_NENAH"] == 0]["Study.No"].tolist()

    included_subjects=[]

    for sub_dir in glob.glob(os.path.join(data_dir, "sub-*")):
        sub_id = os.path.basename(sub_dir)
        sID = sub_id.replace("sub-", "").strip()

        with open(excl_mri, 'r') as file:
            lines = file.readlines()

        for line in lines:
            sID = line.strip()  # Strip any extra whitespace or newlines
            if sID not in excl_mri and sID in clinical_included_subjects:
                included_subjects.append(sID)

    return included_subjects, clinical_excluded_subjects

included_subjects, clinical_excluded_subjects = exclude_subjects(mri_excluded_subjects, clinical_scores)

# datadir=PATH, skip_subjects=LIST. Creates two dictionaries with NENAHXXX and NENAHCXXX as keys pointing to corresponding connecvitity matrix. 
def load_connectivity_matrices(subjects, connectome):
    control_matrices = {}
    subject_matrices = {}
    
    for sID in subjects:
        con_path = os.path.join(data_dir, "sub-" + sID, "dwi", "connectome", connectome)
        if os.path.isfile(con_path):
            matrix = pd.read_csv(con_path, header=None).values
            if "C" in sID:  # only controls have C in their ID
                control_matrices[sID] = matrix
            else:
                subject_matrices[sID] = matrix
        else:
            print(f"{sID} does not have connectome-file")
                
    return control_matrices, subject_matrices

control_matrices, subject_matrices = load_connectivity_matrices(included_subjects, "whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv" )



def load_clinical_data(subjects, clinical_scores_xl_file):
    df = pd.read_excel(clinical_scores_xl_file)
    columns = ["Study.No", "INCLUDE_NENAH", "Group", "sex", "WISC_VSI_CompScore", "WISC_WMI_CompScore", "CMS_GenMem_IndScore", "RBMT_Total_Score"]
    clinical_data = df[columns]

    clinical_data = clinical_data[clinical_data["Study.No"].isin(subjects)]

    return clinical_data

clinical_data = load_clinical_data(included_subjects, clinical_scores)





# print some data for checking
print("This is just some data for making sure everything seems fine:")
print("")
##
print("Excluding these subjects on basis of clinical data:")
counter = 0
for sID in clinical_excluded_subjects:
    print(sID)
    counter+=1
print(f"Total of {counter} subjects excluded.")
print("")
##
counter=0
with open(mri_excluded_subjects, 'r') as file:
    skip_subjects = [line.strip() for line in file]
print("Excluding these subjects on basis of MRI data:")
for sID in skip_subjects:
    print(sID)
    counter+=1
print(f"Total of {counter} subjects excluded")
print("")
##
print("These subjects are included:")
counter=0
for sID in included_subjects:
    print(sID)
    counter+=1
print(f"Total of {counter} subjects included. ")
##
print(f"Control group matrices: {len(control_matrices)}")
print(f"Subject group matrices: {len(subject_matrices)}")
print(clinical_data.head())

