import os
import numpy as np
import glob
import pandas as pd
from scipy.stats import mannwhitneyu
import statsmodels.stats.multitest as smm


data_dir = "/data/iridis/NENAH_BIDS/derivatives/dMRI"


def load_connectivity_matrices(data_dir):
    subject_matrices = []
    control_matrices = []
    
    for sub_dir in glob.glob(os.path.join(data_dir, "sub-*")):
        sub_id = os.path.basename(sub_dir)
        sID = sub_id.replace("sub-", "")
        
        file_path = os.path.join(sub_dir, "dwi", "connectome", "whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv")
        if os.path.isfile(file_path):
            matrix = pd.read_csv(file_path, header=None).values
            if "C" in sID:  # only controls have C in their ID
                control_matrices.append(matrix)
            else:
                subject_matrices.append(matrix)
    
    return subject_matrices, control_matrices




def extract_connectivity_values(group):
    n = len(group)
    p = group[0].shape[0]
    values = np.zeros((n, p, p))
    
    for i in range(n):
        values[i] = group[i]
        
    return values


subjects, controls = load_connectivity_matrices(data_dir)

subject_values = extract_connectivity_values(subjects)
control_values = extract_connectivity_values(controls)

# perform Mann Whitney U test for the two groups 
p = subject_values.shape[1]
p_values = np.zeros((p, p))

for i in range(p):
    for j in range(i + 1, p):
        subj_conn = subject_values[:, i, j]
        ctrl_conn = control_values[:, i, j]
        _, p_value = mannwhitneyu(subj_conn, ctrl_conn, alternative='two-sided')
        p_values[i, j] = p_value
        p_values[j, i] = p_value  # symmetric matrix

# flatten p-values and apply multiple comparison correction
flat_p_values = p_values[np.triu_indices(p, k=1)]
_, corrected_p_values, _, _ = smm.multipletests(flat_p_values, method='fdr_bh')

# reshape corrected p-values back into a matrix
corrected_p_matrix = np.zeros_like(p_values)
corrected_p_matrix[np.triu_indices(p, k=1)] = corrected_p_values
corrected_p_matrix += corrected_p_matrix.T  # Symmetric matrix


output_dir = "/data/iridis/NENAH_BIDS/code/NENAH-BIDS/analysis/mann_whitney_u/outputs/"
output_file = os.path.join(output_dir, "corrected_p_values_matrix.csv")

# save matrix to file
np.savetxt(output_file, corrected_p_matrix, delimiter=",")


print(f"Corrected p-values matrix saved in /mann_whitney_u/outputs/ as .CSV")


alpha = 0.05 

# identify significant connections
significant_connections = []

for i in range(p):
    for j in range(i + 1, p):
        if corrected_p_matrix[i, j] < alpha:
            significant_connections.append((i, j))


csv_file = os.path.join(output_dir, "connections.csv")

with open(csv_file, 'w') as f:
    f.write("Region 1,Region 2\n")
    for conn in significant_connections:
        f.write(f"{conn[0]},{conn[1]}\n")

print(f"Significant connections saved to /outputs/connections.csv")