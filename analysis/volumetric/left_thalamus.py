## Left Thalamus: 

# Import necessary libraries
import os
import pandas as pd
import numpy as np
from scipy import stats
import matplotlib.pyplot as plt
import ptitprince as pt  # For raincloud plots
import seaborn as sns
from statsmodels.formula.api import ols
import statsmodels.api as sm

# ============================
# SET WORKING DIRECTORY (CHANGE IF RUNNING ON NEW DATA)
# ============================

studydir = os.getcwd()  
datadir = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "volumetric")
os.chdir(datadir)  # Change this path to the folder where your data is stored

# ============================
# READ THE DATASET (CHANGE FILE NAME IF USING NEW DATA)
# ============================
# Read CSV file, assuming `;` is the separator and `,` is the decimal format (change if different)
data = pd.read_csv("data_freesurfer_for_stats.csv", sep=',')
data.columns = data.columns.str.strip()
print(data.head())
print(data.columns)

# ============================
# DATA PREPROCESSING
# ============================
# Replace hyphens in column names with underscores (useful for compatibility in regression models)
data.columns = data.columns.str.replace('-', '_')

# Exclude rows where the "Age" column has values 1, 2, 3, or 4
# (If age filtering criteria change, modify this list)
data = data[~data["Age_MRI_NENAH"].isin([1, 2, 3, 4])]

# Separate the dataset into two groups: Controls (0) and Patients (1)
# Ensure the "Group" column exists and contains 0 (controls) and 1 (patients)
controls = data[data["Group_HIE_or_Control"] == 0]
patients = data[data["Group_HIE_or_Control"] == 1]

# ============================
# DEFINE STRUCTURE NAMES FOR ANALYSIS
# ============================
# Assuming the first 12 columns are metadata (e.g., ID, Age, Sex, etc.), structure names start from column 13
# If using a different dataset, check where the structural brain volume columns start

###structure_names = data.columns[12:]  # Modify if necessary
structure_names = ['Left_Whole_thalamus']

# ============================
# APPLY BONFERRONI CORRECTION FOR MULTIPLE COMPARISONS
# ============================
# Corrected p-value threshold to reduce false positives
corrected_p_value = 0.05 / len(structure_names)

# ============================
# RUN ANCOVA FOR EACH BRAIN STRUCTURE
# ============================
for structure in structure_names:
    # Combine controls and patients back into a single dataset (ensures all data is included in the model)
    filtered_data = pd.concat([controls, patients], axis=0)

    # ANCOVA model: Predict structure volume based on Group, Age, Sex, and Whole Thalamus Volume
    # Ensure 'Left_Whole_thalamus' exists in the dataset, change column name if needed
    model = ols(f"Q('{structure}') ~ Group_HIE_or_Control + Age_MRI_NENAH + Sex_at_birth + Q('Left_Whole_thalamus')", data=filtered_data).fit()

    # Perform ANOVA on the model to extract statistical significance of Group (patients vs controls)
    anova_table = sm.stats.anova_lm(model, typ=2)
    p_value = anova_table.loc["Group_HIE_or_Control", "PR(>F)"]

    # ============================
    # PRINT RESULTS (SIGNIFICANCE TEST)
    # ============================
    # Check if the p-value is below the Bonferroni-corrected threshold
    if p_value < corrected_p_value:
        print(f"The difference in {structure} volumes between controls and patients is significant after Bonferroni correction (p = {p_value:.4f}).")
    else:
        print(f"The difference in {structure} volumes between controls and patients is not significant after Bonferroni correction (p = {p_value:.4f}).")

    # ============================
    # CREATE RAINCLOUD PLOTS
    # ============================
    # Combine the structure volume data into a new DataFrame for visualization
    combined_data = pd.concat([controls[structure], patients[structure]], axis=0)
    group_labels = ['Controls'] * len(controls) + ['Patients'] * len(patients)
    plot_data = pd.DataFrame({'Group': group_labels, 'Volume': combined_data, 'Structure': [structure] * len(combined_data)})

    # Plot the Raincloud visualization
    plt.figure(figsize=(6, 6))
    pt.RainCloud(x='Group', y='Volume', data=plot_data, width_viol=.6, width_box=.2, orient='h')
    plt.title(f"{structure} Volumes (p = {p_value:.4f})")

    # ============================
    # SAVE PLOT TO FILE
    # ============================
    # Saves the plot with the structure name as the filename
    plt.savefig(f"{structure}_Volumes.png", dpi=300, bbox_inches='tight')
    plt.show()
