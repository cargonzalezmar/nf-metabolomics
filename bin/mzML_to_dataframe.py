#!/usr/bin/env python

import sys
from pyopenms import *

exp = MSExperiment()
MzMLFile().load(sys.argv[1], exp)

df = exp.get_df()
df["mslevel"] = [spec.getMSLevel() for spec in exp]

df["precursors"] = [spec.getPrecursors()[0].getMZ() if spec.getPrecursors() else "none" for spec in exp]

ms1_to_ms2 = [[] for _ in exp]

i = 0
while i < len(df["mslevel"]):
    if df["mslevel"][i] == 1:
        j = i+1
        if j < len(df["mslevel"]):
            while df["mslevel"][j] == 2:
                ms1_to_ms2[i].append(j)
                ms1_to_ms2[j].append(i)
                if (j == (len(df["mslevel"])-1)):
                    break
                else:
                    j += 1
        i = j
    else:
        i += 1

df["ms1<->ms2"] = ms1_to_ms2
df.to_pickle(sys.argv[2])