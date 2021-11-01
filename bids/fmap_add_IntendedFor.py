# First, import packages
import json
import os
import sys

# Example command line inputs: fmap_add_IntendedFor.py phasediff bold1 bold2 ...
#       - sys.argv[1]: sub-NENAH012/fmap/sub-NENAH012_acq-gre_dir-AP_run-1_phasediff.json
#       - sys.argv[2]: sub-NENAH012/func/sub-NENAH012_task-rest_dir-AP_run-1_bold.nii.gz
#       - sys.argv[3]: sub-NENAH012/func/sub-NENAH012_task-rest_dir-AP_run-2_bold.nii.gz

# Taking multiple command line arguments
# https://stackoverflow.com/questions/1643643/how-to-test-for-multiple-command-line-arguments-sys-argv

boldfile_list = []
for boldfile in sys.argv[2:]:
    boldfile_list.append(str(boldfile))

# Take input from argument
json_from_phasediff = str(sys.argv[1])

with open(json_from_phasediff) as jsonFile:
    jsonObject = json.load(jsonFile)
    jsonFile.close()

# Next, add IntendedFor
#json_newObj = {}
#for element in jsonObject:
#    if element != 'IntendedFor' and element != 'Units':
#        json_newObj[element] = jsonObject[element]
jsonObject['IntendedFor'] = boldfile_list

# Finally, update the json file
# https://stackoverflow.com/questions/17055117/python-json-dump-append-to-txt-with-each-variable-on-new-line
with open(json_from_phasediff, 'w') as jsonFile:
    json.dump(jsonObject, jsonFile, indent=2)
    #json.dump(json_newObj, jsonFile, indent=2)
    jsonFile.close()
