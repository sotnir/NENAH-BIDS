import os
import pandas as pd

# filepaths
studydir = os.getcwd()  
data_dir = os.path.join(studydir, "derivatives", "sMRI_fs-segmentation")  
clinical_data = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "clinical_data", "NENAH_SchoolAge_full_dataset.xlsx")

# hardcoded list of subjects who did not pass quality control for MRI data
mri_excluded_subjects = ["NENAH02", "NENAHC004", "NENAH052", "NENAH017", "NENAH008", "NENAH014", "NENAH036"]

# load the clinical data
df = pd.read_excel(clinical_data, header=1)
df.columns = df.columns.str.strip().str.replace(' ', '_').str.replace('(', '').str.replace(')', '')
df = df[['HIE_Child_ID_NENAH', 'Group_HIE_or_Control', 'Age_MRI_NENAH', 'Sex_at_birth']]
print(df.columns)


# convert columns to appropriate data types
df['Group'] = df['Group'].astype(int)
df['Age'] = pd.to_numeric(df['Age'], errors='coerce')
df['Sex'] = df['Sex'].astype(int)

# exclude subjects who did not pass MRI quality control
df = df[~df['Subject'].isin(mri_excluded_subjects)]


# initialize new columns for thalamus volumes
df['Left_Whole_thalamus'] = None
df['Right_Whole_thalamus'] = None

# loop through the subjects
for index, row in df.iterrows():
    sub_id = row['Subject']
    sub_dir = os.path.join(data_dir, f"sub-{sub_id}", "mri")
    thalamus_file = os.path.join(sub_dir, "ThalamicNuclei.v13.T1.volumes.txt")

    # check if the file exists
    if os.path.isfile(thalamus_file):
        # read the file and parse the volume
        with open(thalamus_file, 'r') as file:
            lines = file.readlines()
            for line in lines:
                if 'Left-Whole_thalamus' in line:
                    left_vol = float(line.split()[1])
                    df.at[index, 'Left_Whole_thalamus'] = left_vol
                if 'Right-Whole_thalamus' in line:
                    right_vol = float(line.split()[1])
                    df.at[index, 'Right_Whole_thalamus'] = right_vol

# drop rows with missing thalamus volume data
df.dropna(subset=['Left_Whole_thalamus', 'Right_Whole_thalamus'], inplace=True)

# display the cleaned and updated data
print(df.head())

# save the cleaned data to a new file
output_path = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "volumetric", "data_freesurfer_for_stats.csv")
df.to_csv(output_path, index=False)