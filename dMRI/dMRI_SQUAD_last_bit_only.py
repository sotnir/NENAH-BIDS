# Routine for running SQUAD in study
# and saving to QC_SQUAD.tsv file
####################################################
## Decide QC pass_fail from Traffic Light Criteria

import os, shutil, json
import json
import numpy as np
import pandas as pd

# Define derivatives folder
derivatives = '/data/1TSSD/NENAH_BIDS/derivatives/dMRI'
squadlistfile = os.path.join(derivatives,f'sub-NENAHGRP/qc/squad_quad_folders_exclNENAHC041.txt')
squadfolder = os.path.join(derivatives,f'sub-NENAHGRP/qc/squad_with_grouping_exclNENAHC041')

# Read the included quadfolder
with open(squadlistfile, 'r') as f:
  quadfolders = f.read()

# Read SQUAD output (GROUP JSON-file)
with open(os.path.join(squadfolder,'group_db.json'), 'r') as f:
  squad = json.load(f)
# and put into dataframes
df1 = pd.DataFrame(squad["qc_motion"], columns=['qc_motion_abs',  'qc_motion_rel'], dtype = float)
#df2 = pd.DataFrame(squad["qc_cnr"], columns=['qc_snr_b0',  'qc_cnr_b1000',  'qc_cnr_b2600'], dtype = float)
df3 = pd.DataFrame(squad["qc_outliers"], columns=['qc_outliers_tot', 'qc_outliers_b1000', 'qc_outliers_b2600','qc_outliers_pe','qc_outliers_unknown_check_with_pdf'], dtype = float)
# and a final dataframe
df =  pd.concat([df1, df3['qc_outliers_tot']], axis=1, join='outer')
#df =  pd.concat([df1,df2, df3['qc_outliers_tot']], axis=1, join='outer')

# Create dataframe for deciding QC
dfqc = pd.DataFrame(np.zeros(df.shape)) # same shape as df but filled with zeros
dfqc.columns = df.columns
# set the entries in dfqc according to  
# Traffic Light system that is the output from SQUAD (GREEN with 1 SD; MODERATE = YELLOW between 1-2 SD; SEVERE = RED above 2 SD).
dfqc[abs( df.mean(axis=0) - df ) < 2 * df.std(axis=0) ] = 0.5
dfqc[abs( df.mean(axis=0) - df ) < 1 * df.std(axis=0) ] = 1

####################################################
## Write to output file
# Get sID and ssID:s from quadfolders
sID_ssID = [s.replace("../../", "") for s in quadfolders]
sID = [s.replace("qc/eddy_quad", "") for s in sID_ssID]
df_sID_ssID = pd.DataFrame(sID, columns=["participant_id"])

# rename the columns
dfqc.rename(columns = {'qc_motion_abs':'qc_motion_abs_pass_fail',
                       'qc_motion_rel':'qc_motion_rel_pass_fail',
                       'qc_outliers_tot':'qc_outliers_tot_pass_fail'}, 
                       inplace = True)
#dfqc.rename(columns = {'qc_motion_abs':'qc_motion_abs_pass_fail',
#                       'qc_motion_rel':'qc_motion_rel_pass_fail',
#                       'qc_snr_b0':'qc_snr_b0_pass_fail',
#                       'qc_cnr_b0400':'qc_cnr_b0400_pass_fail',
#                       'qc_cnr_b1000':'qc_cnr_b1000_pass_fail',
#                       'qc_cnr_b2500':'qc_cnr_b2500_pass_fail',
#                       'qc_outliers_tot_pass_fail':'qc_outliers_tot_pass_fail'}, 
#                       inplace = True)

dfqc =  pd.concat([df_sID_ssID, dfqc], axis=1, join='outer')
dfqc = dfqc.sort_values( by = 'participant_id')
# and write to output-file
squadqctsv = os.path.join(squadfolder,'QC_SQUAD.tsv')
dfqc.to_csv(squadqctsv, sep="\t", index=False)
