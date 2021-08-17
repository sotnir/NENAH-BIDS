#!/bin/bash

# Find all subject files in /rawdata
filename=($(find rawdata/sub*/dwi/*dwi.json -type f | sort))
dicomdir=($(find rawdata/sub*/dwi/*dwi.json -type f | sort | cut -d/ -f2 | cut -d- -f2))
newname=($(find rawdata/sub*/dwi/*dwi.json -type f | sort | cut -d/ -f4 | cut -d. -f1))
Index=($(find rawdata/sub*/dwi/*dwi.json -type f | wc -l))

mkdir -p derivatives/slice_timings

for ((i=0;i<$Index;i++))
do

echo Now finding keyval for ${newname[i]}

mrinfo -json_keyval derivatives/slice_timings/${newname[i]}_keyval.json dicomdir/${dicomdir[i]}

done
