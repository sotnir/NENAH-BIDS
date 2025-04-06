import os
import pandas as pd
import numpy as np
import glob

# === PARAMETERS ===
studydir = os.getcwd()
data_dir = os.path.join(studydir, "derivatives", "dMRI")
output_base = os.path.join(studydir, "code", "NENAH-BIDS", "analysis", "NBS", "connectivity_matrices")

# define connectomes to export (remove prefix when naming folders)
connectomes = [
    "whole_brain_10M_sift2_space-anat_thalamus_lobes_connectome.csv",
    "whole_brain_10M_sift2_space-anat_fs_thomas-thalamic-nuclear-groups_connectome.csv",
    "whole_brain_10M_sift2_space-anat_fs_thalamus_connectome.csv",
    "whole_brain_10M_sift2_space-anat_fs-ctx_thomas-thalamic-nuclear-groups_connectome.csv",
    "whole_brain_10M_space-anat_mean_FA_connectome.csv"
]

# subjects excluded from mri stage
excluded_subjects = ["NENAH02", "NENAHC004", "NENAH052", "NENAH017", "NENAH008", "NENAH014", "NENAH036", "NENAHGRP"]

# === MAIN FUNCTION ===
def extract_connectomes(connectome_filename):
    out_folder_name = connectome_filename.replace("whole_brain_10M_sift2_space-anat_", "").replace(".csv", "")
    output_dir = os.path.join(output_base, out_folder_name)
    os.makedirs(output_dir, exist_ok=True)

    for sub_dir in glob.glob(os.path.join(data_dir, "sub-*")):
        sID = os.path.basename(sub_dir).replace("sub-", "")
        if sID in excluded_subjects:
            print(f"Skipping excluded subject: {sID}")
            continue

        conn_path = os.path.join(sub_dir, "anat", "connectome", connectome_filename)
        if os.path.exists(conn_path):
            try:
                mat = pd.read_csv(conn_path, header=None).values
                out_path = os.path.join(output_dir, f"{sID}.txt")
                np.savetxt(out_path, mat, fmt="%.5f")
                print(f"Saved: {sID} → {out_folder_name}")
            except Exception as e:
                print(f"Error reading {conn_path}: {e}")
        else:
            print(f" Missing file for {sID}: {connectome_filename}")

# === RUN ===
#for conn in connectomes:
#    extract_connectomes(conn)


# === GENERATE DESIGN MATRIX ===
def create_design_matrix(from_dir):
    matrix_dir = os.path.join(output_base, from_dir)
    subject_files = sorted([f for f in os.listdir(matrix_dir) if f.endswith(".txt")])

    design_matrix = []
    for fname in subject_files:
        subject_id = fname.replace(".txt", "")
        if "C" in subject_id:
            # control: [0, 1]
            design_matrix.append([1, 1])
        else:
            # patient: [1, 0]
            design_matrix.append([1, 0])

    design_path = os.path.join(matrix_dir, "design_matrix_ttest.txt")
    np.savetxt(design_path, design_matrix, fmt="%d")
    print(f"Design matrix saved: {design_path}")

# run design matrix generation for one folder
create_design_matrix("thalamus_lobes_connectome")