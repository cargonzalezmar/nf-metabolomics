#!/usr/bin/env python

import sys
from pyopenms import *

cm = ConsensusMap()
ConsensusXMLFile().load(sys.argv[1], cm)

df = cm.get_df()

for cf in cm:
    if cf.metaValueExists("best ion"):
        df["adduct"] = [cf.getMetaValue("best ion") for cf in cm]
        break
df["feature_ids"] = [[str(handle.getUniqueId()) for handle in cf.getFeatureList()] for cf in cm]
df= df.reset_index()
df= df.drop(columns= ["sequence"])

df.to_pickle(sys.argv[2])