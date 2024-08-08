import os
import glob
import pandas as pd
import numpy as np
import subprocess

# This is a script to organize data for statistical analysis using the NBS matlab toolbox within the NENAH-study. 

# default params
studydir = os.getcwd()  
data_dir = os.path.join(studydir, "derivatives", "dMRI")  
clinical_scores = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "clinical_data", "NENAH_SchoolAge_memory_FSIQ.xlsx")
dataset = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "clinical_data", "NENAH_SchoolAge_full_dataset.xlsx")
thalamo_cortical_parc = os.path.join("derivatives", "dMRI", "analysis", "NBS", )


# hardcoded list of subjecs who did not pass quality control for MRI data.
mri_excluded_subjects = ["NENAH02", "NENAHC004", "NENAH052", "NENAH017", "NENAH008", "NENAH014", "NENAH036"]



# exclude subjects with faulty clinical data
def exclude_subjects(excl_mri, clinical_data):
    df = pd.read_excel(clinical_data)

    clinical_included_subjects = df[df["INCLUDE_NENAH"] == 1]["Study.No"].tolist()
    clinical_excluded_subjects = df[df["INCLUDE_NENAH"] == 0]["Study.No"].tolist()

    included_subjects=[]

    for sub_dir in glob.glob(os.path.join(data_dir, "sub-*")):
        sub_id = os.path.basename(sub_dir)
        sID = sub_id.replace("sub-", "")

        if sID in clinical_included_subjects and sID not in excl_mri:
            included_subjects.append(sID)

    return included_subjects, clinical_excluded_subjects

included_subjects, clinical_excluded_subjects = exclude_subjects(mri_excluded_subjects, clinical_scores)



# if subject have been scanned once, take that age. If the subject have been scanned twice calculate age of 
# subject on date of second scan. 
def get_subject_ages(dataset_path, subjects):

    df = pd.read_excel(dataset_path)

    subject_ages = {}

    for index, row in df.iterrows():
        subject_id = row['Study.No']
        
        if subject_id in subjects:
            age_mri = row['Age_MRI']
            mri2_date = row['MRI2_NENAH_DATE']

            if pd.isna(mri2_date):
                subject_ages[subject_id] = age_mri
            else:
                mri1_date = pd.to_datetime(row['MRI2_NENAH_DATE'])
                mri2_date = pd.to_datetime(mri2_date)
                time_diff = (mri2_date - mri1_date).days / 365.25

                age_at_mri2 = age_mri + time_diff
                subject_ages[subject_id] = age_at_mri2
    return subject_ages

subject_ages = get_subject_ages(dataset, included_subjects)

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





def load_clinical_data(subjects, clinical_scores_xl_file):
    df = pd.read_excel(clinical_scores_xl_file)
    columns = ["Study.No", "INCLUDE_NENAH", "Group", "sex", "WISC_VSI_CompScore", "WISC_WMI_CompScore", "CMS_GenMem_IndScore", "RBMT_Total_Score"]
    clinical_data = df[columns]

    clinical_data = clinical_data[clinical_data["Study.No"].isin(subjects)]

    return clinical_data

clinical_data = load_clinical_data(included_subjects, clinical_scores)


# generera correlations matriser...
def generate_corr_matrix(connectivity_matrices, clinical_score):
    correlation_matrices = {}

    for subject_id, matrix in connectivity_matrices.items():
        clinical_score = clinical_data.loc[clinical_data['Study.No'] == subject_id, clinical_score].values[0]
        correlation_matrix = np.corrcoef(matrix, clinical_score, rowvar=False)
        correlation_matrices[subject_id] = correlation_matrix

    return correlation_matrices

### create a design matrix 
# score-type can be one of "WISC_VSI_CompScore", "WISC_WMI_CompScore", "CMS_GenMem_IndScore", "RBMT_Total_Score"
# test ancova

def generate_ancova_design_matrix(clinical_data, mri_ages, score_type):

    
    clinical_data_sorted = clinical_data.sort_values(by='Study.No')
    
    design_matrix = pd.DataFrame(index=clinical_data_sorted.index)

    # add intercept (column of ones)
    design_matrix['Intercept'] = 1

    # add group column (0 for controls, 1 for subjects)
    design_matrix['Group'] = clinical_data_sorted['Group'].map({1: 0, 2:1})

    # add sex column
    design_matrix['Sex'] = clinical_data_sorted['sex']

    # add age column (age at the time of MRI scan)
    design_matrix['Age'] = clinical_data_sorted['Study.No'].map(mri_ages)

    # add clinical score (select one score for the analysis)
    design_matrix['Clinical_Score'] = clinical_data_sorted[score_type]

    # add interaction term (Group * Clinical_Score)
    design_matrix['Group_by_group_inter'] = design_matrix['Group'] * design_matrix['Clinical_Score']

    return design_matrix


ancova_design_matrices = "code/NENAH-BIDS/analysis/NBS/design_matrices/ancova"

if not os.path.exists(ancova_design_matrices):
    os.makedirs(ancova_design_matrices, exist_ok=True)

    design_matrix_wisc_vsi_compscore = generate_ancova_design_matrix(clinical_data, subject_ages, "WISC_VSI_CompScore")
    design_matrix_wisc_wmi_compscore = generate_ancova_design_matrix(clinical_data, subject_ages, "WISC_WMI_CompScore")
    design_matrix_cms_genmem_indscore = generate_ancova_design_matrix(clinical_data, subject_ages, "CMS_GenMem_IndScore")
    design_matrix_rbmt_total_score = generate_ancova_design_matrix(clinical_data, subject_ages, "RBMT_Total_Score")

    design_matrices = {
        "design_matrix_wisc_vsi_compscore": design_matrix_wisc_vsi_compscore,
        "design_matrix_wisc_wmi_compscore": design_matrix_wisc_wmi_compscore,
        "design_matrix_cms_genmem_indscore": design_matrix_cms_genmem_indscore,
        "design_matrix_rbmt_total_score": design_matrix_rbmt_total_score,
    }

    for name, matrix in design_matrices.items():
        file_path = os.path.join(ancova_design_matrices, f"{name}.txt")
        matrix.to_string(file_path, header=False, index=False)


def generate_t_test_matrices(clinical_data):

    clinical_data_sorted=clinical_data.sort_values(by='Study.No')

    design_matrix = pd.DataFrame(index=clinical_data_sorted.index)

    design_matrix['Intercept'] = 1

    design_matrix['Group'] = clinical_data_sorted['Group'].map({1: 0, 2:1})

    return design_matrix



t_test_matrices = "code/NENAH-BIDS/analysis/NBS/design_matrices/t_test"

if not os.path.exists(t_test_matrices):
    os.makedirs(t_test_matrices, exists_ok=True)

    t_test_matrix = generate_t_test_matrices(clinical_data)

    file_name = os.path.join(t_test_matrices, 'group_matrix')
    t_test_matrix.to_string(file_name, header=False, index=False)





thalamo_cortical_matrices = "code/NENAH-BIDS/analysis/NBS/connectivity_matrices/whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome"

if not os.path.exists(thalamo_cortical_matrices):
    os.makedirs(thalamo_cortical_matrices, exist_ok=True)

    control_matrices, subject_matrices = load_connectivity_matrices(included_subjects, "whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv" )

    for _, row in clinical_data.iterrows():
        subject_id = row['Study.No']
        if subject_id in control_matrices:
            matrix = control_matrices[subject_id]
        elif subject_id in subject_matrices:
            matrix = subject_matrices[subject_id]
        else:
            print(f"Matrix for {subject_id} not found!")
            continue

        file_path = os.path.join(thalamo_cortical_matrices, f"{subject_id}.txt")

        np.savetxt(file_path, matrix, fmt='%g')

thalamo_cortical_mean_fa_matrices = "code/NENAH-BIDS/analysis/NBS/connectivity_matrices/whole_brain_10M_space-anat_mean_FA_connectome"

if not os.path.exists(thalamo_cortical_mean_fa_matrices):
    os.makedirs(thalamo_cortical_mean_fa_matrices, exist_ok=True)

    control_matrices, subject_matrices = load_connectivity_matrices(included_subjects, "whole_brain_10M_space-anat_mean_FA_connectome.csv" )

    for _, row in clinical_data.iterrows():
        subject_id = row['Study.No']
        if subject_id in control_matrices:
            matrix = control_matrices[subject_id]
        elif subject_id in subject_matrices:
            matrix = subject_matrices[subject_id]
        else:
            print(f"Matrix for {subject_id} not found!")
            continue

        file_path = os.path.join(thalamo_cortical_mean_fa_matrices, f"{subject_id}.txt")

        np.savetxt(file_path, matrix, fmt='%g')


# create COG.mat
# nodes labels for NBS
# These two should be done on parcs in MNI-space 

# print some data for checking
print("")
print("Excluding these subjects on basis of clinical data:")
counter = 0
for sID in clinical_excluded_subjects:
    print(sID)
    counter+=1
print(f"Total of {counter} subjects excluded.")
print("")
##
counter=0
print("Excluding these subjects on basis of MRI data:")
for sID in mri_excluded_subjects:
    print(sID)
    counter+=1
print(f"Total of {counter} subjects excluded")
print("")
##

counter=0
for sID in included_subjects:
    counter+=1
print(f"Total of {counter} subjects included.")
print("First 10 rows of clinical data:")
for index, row in clinical_data.head(10).iterrows():
    print(row.tolist())
