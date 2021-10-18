#!/bin/bash
# Simple script to visualise dMRI rawdata

file=$1
for shell in `mrinfo -shell_bvalues $file`; do 
dwiextract -shells $shell $file - | mrview - -mode 2; 
done



