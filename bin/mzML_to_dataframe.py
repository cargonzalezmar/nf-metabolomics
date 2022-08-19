#!/usr/bin/env python

import sys
from pyopenms import *

exp = MSExperiment()
MzMLFile().load(sys.argv[1], exp)

df = exp.get_df() # default: long = False
df.to_pickle(sys.argv[2])