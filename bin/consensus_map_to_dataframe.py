#!/usr/bin/env python

import sys
from pyopenms import *

cm = ConsensusMap()
ConsensusXMLFile().load(sys.argv[1], cm)

df = cm.get_df()

best_ions = []
for f in cm:
    if f.metaValueExists("best ion"):
        best_ions.append(f.getMetaValue("best ion"))
    else:
        best_ions.append("")

df["best ion"] = best_ions

df.to_csv(sys.argv[2], sep="\t")