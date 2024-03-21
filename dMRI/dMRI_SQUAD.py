## Routine for putting a SQUAD output (group_db.json) into a QC_SQUAD.tsv file
## Decide QC pass_fail from EddyQC Traffic Light Criteria
####################################################

import os, shutil, json
import json
import numpy as np
import pandas as pd

# Define INPUT
# Finn's laptop
studydir = '/Users/fi2313le/Research/Projects/UoS_-_HIE_NENAH-school-age/Data/NENAH_BIDS'
codedir = '/Users/fi2313le/Code/NENAH-BIDS'
# UoS WS
studydir = '/data/1TSSD/NENAH_BIDS'
codedir = studydir + '/code/NENAH-BIDS'
# Define derivatives folder and SQUAD input
derivatives = studydir + '/derivatives/dMRI'
squadlistfile = os.path.join(derivatives,f'sub-NENAHGRP/qc/squad_quad_folders_exclNENAHC041.txt')
squadfolder = os.path.join(derivatives,f'sub-NENAHGRP/qc/squad_with_grouping_exclNENAHC041')

# Put the included participant_id into a dataframe
df0 = pd.read_csv(squadlistfile, sep=" ", header=None)
df0 = df0.replace("../../sub-","", regex=True).replace("/qc/eddy_quad","", regex=True)
df0.columns = ['Subject_ID'] 

# Read SQUAD output (GROUP JSON-file)
with open(os.path.join(squadfolder,'group_db.json'), 'r') as f:
  squad = json.load(f)
# and put into dataframes
df1 = pd.DataFrame(squad["qc_motion"], columns=['qc_motion_abs',  'qc_motion_rel'], dtype = float)
#df2 = pd.DataFrame(squad["qc_cnr"], columns=['qc_snr_b0',  'qc_cnr_b1000',  'qc_cnr_b2600'], dtype = float)
df3 = pd.DataFrame(squad["qc_outliers"], columns=['qc_outliers_tot', 'qc_outliers_b1000', 'qc_outliers_b2600','qc_outliers_pe_dirAP','qc_outliers_pe_dirPA'], dtype = float)
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
# and a column just listing the lowest of a qc values
dfmin  = pd.DataFrame(dfqc.min(axis=1), columns = ["qc_min"])
dfqc =  pd.concat([dfmin, dfqc], axis=1, join='outer')

# rename the columns
dfqc.rename(columns = {'qc_min':'qc_min_pass_fail',
                       'qc_motion_abs':'qc_motion_abs_pass_fail',
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

# include the Subject_ID
dfqc =  pd.concat([df0, dfqc], axis=1, join='outer')
dfqc = dfqc.sort_values( by = 'Subject_ID')
# and write to output-file
squadqctsv = os.path.join(squadfolder,'QC_SQUAD.tsv')
dfqc.to_csv(squadqctsv, sep="\t", index=False)

# Finally, create a QC_dMRI_pipeline.tsv file that goes into codedir/QC for further processing in pipeline
qc_rawdata_anat_file = os.path.join(codedir,'QC','QC_MRIQC_anat.csv')
qc_rawdata_dwi_file = os.path.join(codedir,'QC','QC_dwi.csv')
qc_dMRI_pipeline_dwi_file = os.path.join(codedir,'QC','QC_dMRI_pipeline_dwi.csv')
dfanat = pd.read_csv(qc_rawdata_anat_file, sep=",")
dfdwi = pd.read_csv(qc_rawdata_dwi_file, sep=",")
df = pd.concat([dfanat[["Subject_ID","QC_rawdata_anat_PASS_1_or_FAIL_0"]], dfdwi["QC_rawdata_dwi_PASS_1_FAIL_0"]], axis=1, join='outer')

# Merge the two data frames 
df_merged = pd.merge(df, dfqc[["Subject_ID","qc_min_pass_fail"]], on="Subject_ID", how="left")
# rename
df_merged.rename(columns = {'qc_min_pass_fail':'QC_EddyQC_dwi_PASS_1_FAIL_0'})
# and then save in file
df_merged.to_csv(qc_dMRI_pipeline_dwi_file, sep="\t", index=False)

