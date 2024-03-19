# Routine for running SQUAD in study
# and saving to QC_SQUAD.tsv file

def perform_process(processcall) :
    import os, subprocess
    # Perform the process given by the processcall by launching into terminal
    p=subprocess.Popen(processcall, stdout=subprocess.PIPE, shell=True)
    # Poll process.stdout to show stdout live
    while True:
        output = p.stdout.readline()
        if p.poll() is not None:
            break
        if output:
            print(output.strip().decode("utf-8"))
    rc = p.poll()

####################################################
## START

import os, shutil, json
from glob import glob

# Define derivatives folder
derivatives = '/data/1TSSD/NENAH_BIDS/derivatives/dMRI'
# and list sub-sID that have done quad
quadfolders = glob(os.path.join(derivatives,'sub-NENAH*','qc/eddy_quad'))

# Create squad folder in sub-GROUP/qc/squad
squadfolder = os.path.join(derivatives,f'sub-GROUP/qc/eddy_squad')
if not os.path.exists(squadfolder): # then make this directory
    os.makedirs(squadfolder)
# and write the squadlist file to this (required as input to eddy_quad)
squadlistfile = os.path.join(squadfolder,'squad_list.txt')
if not os.path.isfile(squadlistfile):
    with open(squadlistfile, "w") as outfile:
        outfile.write("\n".join(quadfolders))

####################################################
# Now run SQUAD (eddy_squad)
squadtmpoutputfolder = os.path.join(squadfolder,'tmp')
processcall = f"eddy_squad {squadlistfile} -o {squadtmpoutputfolder}"
perform_process(processcall)
# and move the output in /tmp up to squadfolder (this is workaround as eddy_quad will not use and existing output folder)
for file in os.listdir(squadtmpoutputfolder):
    shutil.move(os.path.join(squadtmpoutputfolder,file), squadfolder)
# and delete tmp output folder
if os.path.isdir(squadtmpoutputfolder):
    shutil.rmtree(squadtmpoutputfolder)

####################################################
## Decide QC pass_fail from Traffic Light Criteria
        
# Read SQUAD output (GROUP JSON-file)
import json
import numpy as np
import pandas as pd
with open(os.path.join(squadfolder,'group_db.json'), 'r') as f:
  squad = json.load(f)
# and put into dataframes
df1 = pd.DataFrame(squad["qc_motion"], columns=['qc_motion_abs',  'qc_motion_rel'], dtype = float)
#df2 = pd.DataFrame(squad["qc_cnr"], columns=['qc_snr_b0',  'qc_cnr_b1000',  'qc_cnr_b2600'], dtype = float)
df3 = pd.DataFrame(squad["qc_outliers"], columns=['qc_outliers_tot', 'qc_outliers_b1000', 'qc_outliers_b2500','qc_outliers_pe'], dtype = float)
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
sID_ssID = [s.replace(derivatives+"/", "") for s in quadfolders]
sID = [s.replace("qc/eddy_quad", "") for s in sID_ssID]
df_sID_ssID = pd.DataFrame(sID, columns=["participant_id"])

# rename the columns
dfqc.rename(columns = {'qc_motion_abs':'qc_motion_abs_pass_fail',
                       'qc_motion_rel':'qc_motion_rel_pass_fail',
                       'qc_outliers_tot_pass_fail':'qc_outliers_tot_pass_fail'}, 
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

