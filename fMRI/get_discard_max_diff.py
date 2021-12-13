#!/usr/bin/env python

import os, sys
import numpy as np

content = np.loadtxt(sys.argv[1], skiprows=1).ravel()

if len(content) == 0:
    content_complete = np.array([0, 250], dtype=np.float64)
else:
    # Only add 0 if the first volume is not 0
    if content[0] != 0:
        content_complete = np.insert(content, 0, 0)
    # Only add 250 if the last volume is not 250
    if content[len(content)-1] != 250:
     content_complete = np.append(content_complete, 250)

content_complete_max = np.diff(content_complete).max().astype('int')

output_filename = os.path.splitext(sys.argv[1])[0] + '_maxdist.txt'
with open(output_filename, 'w') as f:
    f.write(content_complete_max.astype('str') + '\n')
