# fMRI Quality Assessment using carpet plot and framewise displacement
# Author: Yukai Zou
# Date Created: 1 Nov 2021
# Date Modified: 12 Jan 2022

# Before Start
# 1) Connect to VPN;
# 2) Connect to CNDNG research filestore
# 3) To clean data, make sure sub-NENAH008 run1 is removed
# 4) Sync /Volumes/cndng/NENAH/NENAH_BIDS/derivatives/fMRI:
 #   rsync -aP --include=*/ --include=*/fsl_motion_outliers_FD035/ \
 #             --include=*/fsl_motion_outliers_FD035/*.txt \
 #             --include=*/fsl_motion_outliers_FD035/*.png \
 #             --exclude=* --prune-empty-dirs \
 # yz23e20@NENAH:/local/scratch/disk2/research/NENAH_BIDS/derivatives/fMRI .

setwd("/Volumes/cndng/NENAH/Scanning")
library(tidyverse); library(tidyr); library(reshape2)

path_to_fMRI <- "/Volumes/cndng/NENAH/NENAH_BIDS/derivatives/fMRI"

list_discard_vol2volmotion_FD035 <- read.table("rawdata/20220111_fsl_motion_outliers-discarded_vols_vol2volmotion-FD035_list.txt", header=F) %>% filter(!grepl("sub-NENAH008/fsl_motion_outliers_FD035/discarded_vols_vol2volmotion_run-1.txt", V1))

# Read in maximal distance based on discarded text files
list_discard_maxdist_vol2volmotion_FD035 <- read.table("rawdata/20220111_fsl_motion_outliers-discarded_maxdist_vol2volmotion-FD035_list.txt", header=F) %>% filter(!grepl("sub-NENAH008/fsl_motion_outliers_FD035/discarded_vols_vol2volmotion_run-1_maxdist.txt", V1))

# SubjectID_runID
sID <- sapply(strsplit(list_vol2volmotion_FD035$V1, "/"), 
              function(x) substr(x[1], nchar(x[1])-3, nchar(x[1])))
rID <- sapply(strsplit(list_vol2volmotion_FD035$V1, "\\."), 
              function(x) substr(x[1], nchar(x[1]), nchar(x[1])))
sID_rID <- paste0(sID, "_", rID)

path_to_vol2volmotion_FD035 <- paste0(path_to_fMRI,"/",list_vol2volmotion_FD035 %>% pull(V1))

# A range of discarded FD values
path_to_discard_vol2volmotion_FD035 <- paste0(path_to_fMRI,"/",list_discard_vol2volmotion_FD035 %>% pull(V1))

# Read in maximal distance based on discarded text files
path_to_discard_maxdist_vol2volmotion_FD035 <- paste0(path_to_fMRI,"/",list_discard_maxdist_vol2volmotion_FD035 %>% pull(V1))

create_carp_outliers <- function(Path = path_to_discard_vol2volmotion) {
        report <- NULL
        for (i in 1:length(Path)) {
                l1 <- read.csv(Path[i], header = F)$V1[-1] %>% as.numeric()
                n1 <- rep(0,250)
                n1[l1] <- 1
                report <- rbind(report, n1)
        }
        
        report2 <- data.frame(report) %>% 
                transform(Subject = factor(sID_rID)) %>% 
                melt("Subject") %>% 
                transform(value = factor(value)) %>%
                dplyr::rename(discard = value) %>% as_tibble()
        return(report2)
}

concat_discarded_maxdist <- function(Path = path_to_discard_maxdist_vol2volmotion_FD035) {
        report <- NULL
        for (i in 1:length(Path)) {
                l1 <- read.table(Path[i], header = F)$V1
                report <- rbind(report, l1)
        }
        
        report2 <- data.frame(report) %>% 
                transform(Subject = factor(sID_rID)) %>%
                dplyr::rename(maxdist = report)
        return(report2)
}

write.csv(concat_discarded_maxdist(Path = path_to_discard_maxdist_vol2volmotion_FD035), "processed/20220111_discarded_maxdist_vol2volmotion_FD035.csv", row.names = F)

# A range of discarded FD thresholds at 0.35
gVol2volmotion_outlier_FD035 <- create_carp_outliers(path_to_discard_vol2volmotion_FD035) %>% dplyr::rename(discard.FD035 = discard)

# write.csv(gVol2volmotion_outlier_FD035, "processed/20220111_vol2volmotion_outlier_FD035 timeseries.csv", row.names=F)

# gVol2volmotion_outlier_FD035 <- read.csv("processed/20220108_vol2volmotion_outlier_FD035 DVARS timeseries.csv") %>% as_tibble()
gVol2volmotion_outlier_FD035$Subject <- factor(gVol2volmotion_outlier_FD035$Subject)
gVol2volmotion_outlier_FD035[,grepl("discard", names(gVol2volmotion_outlier_FD035))] <- lapply(gVol2volmotion_outlier_FD035[,grepl("discard", names(gVol2volmotion_outlier_FD035))], factor)
gVol2volmotion_outlier_FD035$variable <- factor(gVol2volmotion_outlier_FD035$variable, levels = paste0("X", seq(1:250)))

dat_maxdist_FD035 <- read.csv("processed/20220111_discarded_maxdist_vol2volmotion_FD035.csv", stringsAsFactors = T)

gVol2volmotion_outlier_FD035 <- gVol2volmotion_outlier_FD035 %>% left_join(dat_maxdist_FD035)

Subj_maxdist <- dplyr::select(gVol2volmotion_outlier_FD035, Subject, maxdist) %>% unique()

# Relevel Subj according to max distance between discarded volumes
string_relevel_Subj_maxdist <- as.character(Subj_maxdist$Subject[order(Subj_maxdist$maxdist)])
gVol2volmotion_outlier_FD035$Subject <- factor(gVol2volmotion_outlier_FD035$Subject, levels = string_relevel_Subj_maxdist)

## GGPLOT
ggplot(gVol2volmotion_outlier_FD035, aes(variable, Subject, fill=discard.FD035)) +
        geom_tile() +
        scale_fill_manual(values = c("black", "cyan")) +
        scale_x_discrete(breaks = c("X1","X50","X100","X150","X200","X250")) +
        ylim(levels(gVol2volmotion_outlier_FD035$Subject)) +
        xlab("Volume-to-volume head displacement")
