import os
import pandas as pd

# filepaths

studydir = os.getcwd()  
data_dir = os.path.join(studydir, "derivatives", "sMRI_fs-segmentation")  
clinical_data = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "clinical_data", "NENAH_SchoolAge_full_dataset.xlsx")

# hardcoded list of subjects who did not pass quality control for MRI data
mri_excluded_subjects = ["NENAH02", "NENAHC004", "NENAH052", "NENAH017", "NENAH008", "NENAH014", "NENAH036"]

# load the clinical data
df = pd.read_excel(clinical_data, sheet_name=0)

# extract relevant columns and rename for convenience
df = df[['Study.No', 'Group', 'AGE_NENAH_Tests', 'sex']]
df.columns = ['Subject', 'Group', 'Age', 'Sex']

# convert columns to appropriate data types
df['Group'] = df['Group'].astype(int)
df['Age'] = pd.to_numeric(df['Age'], errors='coerce')
df['Sex'] = df['Sex'].astype(int)

# exclude subjects who did not pass MRI quality control
df = df[~df['Subject'].isin(mri_excluded_subjects)]


# check for missing values in relevant columns and print the Subject ID if any are found
missing_data = df[df[['Group', 'Age', 'Sex']].isna().any(axis=1)]
if not missing_data.empty:
    print("Subjects with missing Group, Age, or Sex data (will be excluded):")
    print(missing_data['Subject'].tolist())


# drop rows with missing values in the relevant columns
df.dropna(subset=['Group', 'Age', 'Sex'], inplace=True)

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
output_path = '/path/to/your/directory/cleaned_clinical_data_with_thalamus.csv'
df.to_csv(output_path, index=False)