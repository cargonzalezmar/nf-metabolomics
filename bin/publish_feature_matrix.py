#!/usr/bin/env python

import sys
import pandas as pd

df = pd.read_pickle(sys.argv[1])

df.to_csv(sys.argv[2], sep="\t", index=False)