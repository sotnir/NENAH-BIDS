## First, import packages

import json
import os
import sys

"""## Read in json from BIDS"""

# Take input from argument
json_from_bids = str(sys.argv[1])

with open(json_from_bids) as jsonFile:
    jsonObject = json.load(jsonFile)
    jsonFile.close()

"""## Read in json from Raw DICOM, get SliceTiming"""

# Take input from argument
json_from_raw = str(sys.argv[2])

with open(json_from_raw) as jsonFile:
    jsonObject_raw = json.load(jsonFile)
    jsonFile.close()

new_SliceTiming = jsonObject_raw['SliceTiming']

"""## Replace SliceTiming in BIDS with Syngo"""

jsonObject['SliceTiming'] = new_SliceTiming

"""## Finally, save as new json file"""

# https://stackoverflow.com/questions/17055117/python-json-dump-append-to-txt-with-each-variable-on-new-line

filename = str(sys.argv[1]).split('.')[0]
with open(filename + '_SliceTiming_added.json', 'w') as jsonFile:
    json.dump(jsonObject, jsonFile, indent=2)
    jsonFile.close()
